#!/bin/bash

kind create cluster --config cluster.yaml

kubectl create namespace dev-ns

helmfile apply