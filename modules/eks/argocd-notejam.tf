
resource "kubectl_manifest" "test" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: notejam
  namespace: default
spec:
  destination:
    namespace: default
    server: https://kubernetes.default.svc
  project: default
  source:
    path: notejam/
    repoURL: https://github.com/nc-demo/k8s-env-poc
    targetRevision: main
  sync:
    comparedTo:
      destination:
        namespace: default
        server: https://kubernetes.default.svc
      source:
        path: notejam/
        repoURL: https://github.com/nc-demo/k8s-env-poc
        targetRevision: main
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
YAML
}
