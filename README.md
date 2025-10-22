# EKS Microservices Demo CI/CD (DevOps Project)

End-to-end DevOps project that provisions AWS EKS with Terraform, installs core Kubernetes add‑ons with Helm, and deploys the Online Boutique microservices app via Kustomize. GitHub Actions validates manifests, deploys to EKS, and smoke‑tests via the ALB Ingress.

Focus areas: production‑style Terraform (remote state + locking), IRSA for AWS controllers, schema validation, namespaced environments, and autoscaling.

## Highlights
- Infrastructure as Code: Modular Terraform for IAM, EKS, and networking with S3 backend and DynamoDB state locking.
- Kubernetes on AWS: EKS cluster + managed add‑ons (VPC CNI, CoreDNS, Kube Proxy, Metrics Server).
- Secure Controllers: AWS Load Balancer Controller via IRSA (OIDC) and Helm.
- App Delivery: Kustomize overlay for the Online Boutique with ALB Ingress + HPA.
- CI/CD: GitHub Actions validates (kustomize + kubeconform), deploys to EKS, and runs smoke checks.
- Operational Rigor: Namespaced separation, tagging, Makefile automation, and cost-aware cleanup.

## Architecture
- Terraform layers
  - `envs/dev` provisions EKS in default VPC public subnets (MVP focus on simplicity).
  - `envs/addons` installs platform add‑ons (AWS Load Balancer Controller with IRSA) and namespaces.
- Kubernetes app
  - `apps/microservices-demo/overlays/dev` deploys Online Boutique with:
    - ALB Ingress fronting `frontend-external`.
    - HPA for the `frontend` Deployment.
- CI/CD
  - `.github/workflows/app-cicd.yml` validates manifests, applies overlay to `dev` on `main` pushes, then smoke‑tests via ALB.

## Tech Stack
Terraform, AWS (EKS, IAM, OIDC, ALB), Helm, Kubernetes, Kustomize, GitHub Actions, kubeconform, kubectl.

## Repository Structure
- `envs/dev` — Terraform for EKS, IAM, and networking (S3 backend + DynamoDB locking).
- `envs/addons` — Terraform for namespaces and add‑ons (ALB controller via Helm + IRSA; also creates `dev` and `platform` namespaces).
- `modules/*` — Reusable Terraform modules: `network`, `iam`, `eks`, `addons`.
- `apps/microservices-demo/overlays/dev` — Kustomize overlay (Ingress, HPA, service patch).
- `Makefile` — Convenience targets for infra/apply/destroy.

## Getting Started
Prerequisites
- AWS account/CLI, Terraform >= 1.0, kubectl, Helm, kustomize.
- S3 bucket + DynamoDB table for state/locks. Update names in `envs/dev/backend.tf` and remote-state references in `envs/addons/main.tf` as needed.

Bootstrap infrastructure
- `make infra-apply`
- `aws eks update-kubeconfig --name microservices-demo --region us-east-1`

Install add‑ons and namespaces
- `make addons-apply`

Deploy the app
- `kubectl apply -k apps/microservices-demo/overlays/dev`
- Get ALB hostname:
  - `kubectl get ingress frontend-alb -n dev -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}'`
- Open the hostname in a browser (HPA scales under load; `loadgenerator` is included by upstream manifests).

## CI/CD Pipeline
Triggers
- PRs touching `apps/microservices-demo/**`: render + schema validation.
- Pushes to `main` touching `apps/microservices-demo/**`: validate → deploy → rollout wait → smoke check.

Required GitHub Secrets
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `EKS_CLUSTER_NAME`.

Steps
- Render overlay with kustomize → validate with kubeconform.
- Configure AWS + kubeconfig → apply overlay → wait for `frontend` rollout.
- Extract ALB DNS → HTTP smoke check.

## Operations
- Apply infra: `make infra-apply`
- Apply add‑ons: `make addons-apply`
- Destroy infra: `make infra-destroy`
- Destroy add‑ons: `make addons-destroy`
- Observe scaling: `kubectl top pods -n dev` (metrics-server must be healthy)

## Cost and Cleanup
- Resources incur AWS costs (EKS control plane, nodes, ALB).
- Tear down when done:
  - `kubectl delete -k apps/microservices-demo/overlays/dev`
  - `make addons-destroy`
  - `make infra-destroy`

## Roadmap
- Private subnets and NAT gateways; multi‑AZ node groups.
- ExternalDNS + cert‑manager with ACM for custom domains and TLS.
- Cluster Autoscaler; Prometheus/Grafana for metrics; log shipping.
- Progressive delivery (Argo Rollouts) or GitOps (Argo CD).

