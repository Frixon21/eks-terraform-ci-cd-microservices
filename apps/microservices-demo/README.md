Microservices Demo (Online Boutique) on EKS — MVP overlay

What this overlay does
- Deploys the upstream microservices-demo release into the `dev` namespace.
- Switches the `frontend-external` Service to `ClusterIP` so an ALB Ingress fronts it.
- Creates an ALB-backed Ingress and a basic CPU HPA for the `frontend` Deployment.

How to deploy (after Terraform infra + addons)
1) Ensure namespaces and ALB controller are applied: `make infra-apply && make addons-apply`.
2) Apply the demo in `dev`:
   - `kubectl apply -k apps/microservices-demo/overlays/dev`
3) Get the ALB address:
   - `kubectl get ingress frontend-alb -n dev -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}'`
4) Open the hostname in a browser. Use `kubectl top pods -n dev` to see HPA activity.

Notes
- This overlay references upstream manifests directly from GitHub. If you need a pinned version, change the URL in `overlays/dev/kustomization.yaml` to a specific tag.
- DNS/TLS are out of scope for MVP; use the ALB hostname directly.
- The upstream manifests include a `loadgenerator` to produce traffic; keep it enabled to observe HPA scaling.

