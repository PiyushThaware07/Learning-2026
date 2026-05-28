argocd-learning/
│
├── README.md
├── setup/
│   ├── kind-cluster/
│   │   ├── kind-config.yaml
│   │   └── create-cluster.sh
│   │
│   ├── argocd-install/
│   │   ├── install-argocd.sh
│   │   ├── ingress.yaml
│   │   └── port-forward.sh
│   │
│   └── tools/
│       ├── install-docker.sh
│       ├── install-kubectl.sh
│       └── install-kind.sh
│
├── basics/
│   ├── namespaces/
│   │   └── dev-namespace.yaml
│   │
│   ├── deployments/
│   │   ├── nginx-deployment.yaml
│   │   └── apache-deployment.yaml
│   │
│   ├── services/
│   │   ├── nginx-service.yaml
│   │   └── apache-service.yaml
│   │
│   └── configmaps-secrets/
│       ├── configmap.yaml
│       └── secret.yaml
│
├── argocd/
│   ├── applications/
│   │   ├── nginx-app.yaml
│   │   ├── apache-app.yaml
│   │   └── multi-app.yaml
│   │
│   ├── appprojects/
│   │   ├── dev-project.yaml
│   │   └── prod-project.yaml
│   │
│   ├── repositories/
│   │   └── private-repo-setup.md
│   │
│   ├── sync-policies/
│   │   ├── auto-sync.yaml
│   │   ├── manual-sync.yaml
│   │   └── prune-selfheal.yaml
│   │
│   └── cluster-management/
│       ├── add-cluster.md
│       └── cluster-secret.yaml
│
├── demo-apps/
│   ├── nginx/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── namespace.yaml
│   │
│   ├── apache/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── namespace.yaml
│   │
│   └── guestbook/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── ingress.yaml
│
├── helm/
│   ├── nginx-chart/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │
│   └── argocd-helm-app/
│       └── application.yaml
│
├── kustomize/
│   ├── base/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── kustomization.yaml
│   │
│   ├── overlays/
│   │   ├── dev/
│   │   └── prod/
│   │
│   └── argocd-kustomize-app/
│       └── application.yaml
│
├── multi-cluster/
│   ├── dev-cluster/
│   │   └── app.yaml
│   │
│   ├── prod-cluster/
│   │   └── app.yaml
│   │
│   └── cluster-configs/
│       ├── dev-context.md
│       └── prod-context.md
│
├── advanced/
│   ├── app-of-apps/
│   │   ├── root-app.yaml
│   │   └── child-apps/
│   │
│   ├── notifications/
│   │   ├── slack-config.yaml
│   │   └── email-config.yaml
│   │
│   ├── rollback/
│   │   └── rollback-demo.md
│   │
│   ├── hooks/
│   │   ├── pre-sync-job.yaml
│   │   └── post-sync-job.yaml
│   │
│   └── image-updater/
│       └── updater-config.yaml
│
├── troubleshooting/
│   ├── common-errors.md
│   ├── app-path-errors.md
│   ├── cluster-connection-errors.md
│   └── sync-failures.md
│
└── notes/
    ├── commands.md
    ├── interview-questions.md
    └── architecture.md