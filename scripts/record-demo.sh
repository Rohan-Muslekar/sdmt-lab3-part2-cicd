#!/usr/bin/env bash
#
# record-demo.sh - staging helper for the two Lab 3 Part 2 videos.
#
# The demo is mostly clicking the Jenkins UI and a browser, so this does not
# automate the recording. It prints a tight shot list (so you narrate in
# order and hit ~3 minutes) and opens a tmux session with a live
# kubernetes watch pane, so pods/services coming up are visible on camera.
#
# Usage:
#   ./scripts/record-demo.sh ci        # video 1 shot list: CI (Maven job + Jenkinsfile pipeline)
#   ./scripts/record-demo.sh deploy    # video 2 shot list: CD to GKE + live app
#   ./scripts/record-demo.sh watch     # just the tmux watch panes (no shot list)
#
set -euo pipefail

shot_ci() {
  cat <<'EOF'
VIDEO 1  -  Continuous Integration  (~3 min, both approaches)

  MAVEN APPROACH (binaryCalculate_mvn job)
   1. Show the job config: Git repo URL, pom path, "GitHub hook trigger".
   2. Make a trivial commit + push. Show GitHub webhook delivered (green tick).
   3. Show the build auto-triggering in Jenkins. Open the console output.
   4. Show the commit status flipping to a check mark on GitHub.

  JENKINSFILE APPROACH (BinaryCalculator_pipeline job)
   5. Show "Pipeline script from SCM", Script Path BinaryCalculatorWebapp/Jenkinsfile.
   6. Build Now. Show the stage view: Init -> test -> build -> Deploy all green.
   7. Open console output; point at the mvn test and mvn package lines.

  Say the 5 terms once while pointing at the stage view:
   pipeline (whole thing), agent (where it runs), stage (Init/test/build),
   steps (the sh commands), node (the executor slot).
EOF
}

shot_deploy() {
  cat <<'EOF'
VIDEO 2  -  Continuous Deployment to GKE  (~3 min)

   1. Show the 5 Jenkins credentials: service_account, project_id, repo_path,
      cluster_name, cluster_zone.
   2. Show BinaryCalculator_pipeline_v2 using Jenkinsfile_v2.
   3. Build Now. Walk the stages: test -> build -> containerize -> deployment -> service.
   4. In the containerize stage output, show the image pushed to Artifact Registry.
   5. Cut to the watch pane: pod becomes Running, service gets an EXTERNAL-IP.
   6. Copy the IP. Open http://<EXTERNAL-IP>:8080 in a browser. Use the calculator.
   7. Say: a push to GitHub would re-run this pipeline and roll out the new image.
EOF
}

watch_panes() {
  command -v tmux >/dev/null || { echo "tmux not installed"; exit 1; }
  local s=lab3demo
  tmux kill-session -t "$s" 2>/dev/null || true
  tmux new-session -d -s "$s" -n watch "watch -n2 kubectl get pods"
  tmux split-window -h -t "$s" "watch -n2 kubectl get svc"
  tmux select-pane -t 0
  echo "tmux session '$s' up (pods | services). Attach with: tmux attach -t $s"
  [[ "${DEMO_NO_ATTACH:-}" == 1 ]] || tmux attach -t "$s"
}

case "${1:-}" in
  ci)     shot_ci ;;
  deploy) shot_deploy ;;
  watch)  watch_panes ;;
  *) echo "usage: $0 {ci|deploy|watch}" >&2; exit 1 ;;
esac
