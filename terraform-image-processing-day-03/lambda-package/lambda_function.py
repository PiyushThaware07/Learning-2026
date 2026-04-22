import json
import boto3
import os
import io
import logging
from PIL import Image
from urllib.parse import unquote_plus

logger = logging.getLogger()
logger.setLevel(logging.INFO)


class ImageProcessor:
    def __init__(self):
        self.s3 = boto3.client("s3")

        self.sizes = self._parse_sizes(os.getenv("SIZES", "1024x1024,512x512"))
        self.formats = [f.strip().upper() for f in os.getenv("FORMATS", "JPEG,WEBP").split(",")]
        self.quality = int(os.getenv("QUALITY", "75"))

    # ------------------------
    # Entry
    # ------------------------
    def process_event(self, event):
        for record in event.get("Records", []):
            try:
                bucket = record["s3"]["bucket"]["name"]
                key = unquote_plus(record["s3"]["object"]["key"])

                logger.info(f"Processing file: s3://{bucket}/{key}")

                if self._should_skip(key):
                    logger.info(f"Skipping already processed file: {key}")
                    continue

                img = self._fetch_image(bucket, key)
                base_name = self._get_base_name(key)

                self._process_and_upload(img, bucket, base_name)

                # IMPORTANT: free memory
                img.close()

            except Exception as e:
                logger.error(f"Error processing record: {str(e)}", exc_info=True)

    # ------------------------
    # Helpers
    # ------------------------
    def _should_skip(self, key):
        return key.startswith("processed/")

    def _fetch_image(self, bucket, key):
        response = self.s3.get_object(Bucket=bucket, Key=key)
        image_bytes = response["Body"].read()

        img = Image.open(io.BytesIO(image_bytes))
        img.load()  # force decode early (avoids lazy-load memory spikes)

        if img.mode not in ("RGB",):
            img = img.convert("RGB")

        return img

    def _get_base_name(self, key):
        return os.path.splitext(os.path.basename(key))[0]

    # ------------------------
    # CORE FIX (memory optimized)
    # ------------------------
    def _process_and_upload(self, img, bucket, base_name):
        for size in self.sizes:

            # FIX: avoid copy() + thumbnail mutation issues
            resized = img.resize(size, Image.Resampling.LANCZOS)

            for fmt in self.formats:
                buffer = self._convert_image(resized, fmt)
                output_key = self._build_output_key(size, base_name, fmt)

                self._upload_image(buffer, bucket, output_key, fmt)

            # free resized image per loop
            resized.close()

    def _convert_image(self, image, fmt):
        buffer = io.BytesIO()
        fmt = fmt.upper()

        save_kwargs = {"format": fmt}

        if fmt in ["JPEG", "WEBP"]:
            save_kwargs["quality"] = self.quality
            save_kwargs["optimize"] = True

        image.save(buffer, **save_kwargs)
        buffer.seek(0)

        return buffer

    def _build_output_key(self, size, base_name, fmt):
        return f"processed/{base_name}/{size[0]}x{size[1]}.{fmt.lower()}"

    def _upload_image(self, buffer, bucket, key, fmt):
        self.s3.put_object(
            Bucket=bucket,
            Key=key,
            Body=buffer.getvalue(),  # FIX: safer than passing buffer object
            ContentType=self._get_content_type(fmt)
        )

        logger.info(f"Uploaded: s3://{bucket}/{key}")

    def _get_content_type(self, fmt):
        return {
            "JPEG": "image/jpeg",
            "PNG": "image/png",
            "WEBP": "image/webp"
        }.get(fmt.upper(), "application/octet-stream")

    def _parse_sizes(self, sizes_str):
        sizes = []
        for size in sizes_str.split(","):
            w, h = size.lower().split("x")
            sizes.append((int(w), int(h)))
        return sizes


# ------------------------
# Lambda Handler
# ------------------------
processor = ImageProcessor()

def handler(event, context):
    processor.process_event(event)

    return {
        "statusCode": 200,
        "body": json.dumps("Image processed successfully!")
    }