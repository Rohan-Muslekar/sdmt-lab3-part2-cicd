# sdmt-lab3-part2-cicd

Lab 3 Part 2 for ENGR 5520G (Software Development Methods and Tools): a Jenkins CI/CD pipeline that builds, tests, containerises, and deploys the **BinaryCalculatorWebapp** (Spring Boot, Maven) to Google Kubernetes Engine.

Student: Rohan Muslekar, 101006689.

## Layout

| Path | What it is |
| --- | --- |
| `BinaryCalculatorWebapp/` | the Spring Boot web app, from the lab source |
| `BinaryCalculatorWebapp/Jenkinsfile` | CI pipeline (Init, test, build, Deploy) |
| `BinaryCalculatorWebapp/Jenkinsfile_v2` | CD pipeline to GKE (test, build, containerize, deployment, service) |
| `BinaryCalculatorWebapp/Dockerfile` | image built and pushed by the CD pipeline |
| `jenkins/values.yaml` | Helm values to install Jenkins on the cluster |
| `k8s/` | declarative deployment and service manifests (reference) |
| `scripts/setup-cicd.sh` | reproducible CLI setup (service account, roles, key, Helm install) |
| `scripts/record-demo.sh` | shot lists and a live kube watch for recording the two videos |
| `REPORT.md` | the report source |
| `build_report.py` | renders `REPORT.md` to printable black-and-white HTML |
| `RUNBOOK.md` | step-by-step: what to run, what to click, what to screenshot |

## Quick start

Everything is in `RUNBOOK.md`. Short version:

```bash
mvn clean test -f ./BinaryCalculatorWebapp/pom.xml   # sanity check
./scripts/setup-cicd.sh jenkins                      # Jenkins on the cluster
./scripts/setup-cicd.sh sa                           # service account + key for CD
python3 build_report.py                              # build the report
```

The `BinaryCalculatorWebapp`, `Jenkinsfile`, `Jenkinsfile_v2`, `Dockerfile`, and `jenkins/values.yaml` are the lab-provided files, kept verbatim. Everything else (`k8s/`, `scripts/`, report tooling, runbook) is added for reproducibility.
