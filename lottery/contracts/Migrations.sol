// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.7.0;

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  constructor() public {
    owner = msg.sender;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }
}
permissions:
  contents: 'read'
  id-token: 'write'

steps:
- name: Checkout
  uses: actions/checkout@v2

# Configure Workload Identity Federation and generate an access token.
- id: 'auth'
  name: 'Authenticate to Google Cloud'
  uses: 'google-github-actions/auth@v0'
  with:
    token_format: 'access_token'
    workload_identity_provider: 'projects/123456789/locations/global/workloadIdentityPools/my-pool/providers/my-provider'
    service_account: 'my-service-account@my-project.iam.gserviceaccount.com'

# Alternative option - authentication via credentials json
# - id: 'auth'
#   uses: 'google-github-actions/auth@v0'
#   with:
#     credentials_json: '${{ secrets.GCP_CREDENTIALS }}'

- name: Docker configuration
  run: |-
    echo ${{steps.auth.outputs.access_token}} | docker login -u oauth2accesstoken --password-stdin https://$GAR_LOCATION-docker.pkg.dev
# Get the GKE credentials so we can deploy to the cluster
- name: Set up GKE credentials
  uses: google-github-actions/get-gke-credentials@v0
  with:
    cluster_name: ${{ env.GKE_CLUSTER }}
    location: ${{ env.GKE_ZONE }}

# Build the Docker image
- name: Build
  run: |-
    docker build \
      --tag "$GAR_LOCATION-docker.pkg.dev/$PROJECT_ID/$REPOSITORY/$IMAGE:$GITHUB_SHA" \
      --build-arg GITHUB_SHA="$GITHUB_SHA" \
      --build-arg GITHUB_REF="$GITHUB_REF" \
      .
# Push the Docker image to Google Artifact Registry
- name: Publish
  run: |-
    docker push "$GAR_LOCATION-docker.pkg.dev/$PROJECT_ID/$REPOSITORY/$IMAGE:$GITHUB_SHA"
# Set up kustomize
- name: Set up Kustomize
  run: |-
    curl -sfLo kustomize https://github.com/kubernetes-sigs/kustomize/releases/download/v3.1.0/kustomize_3.1.0_linux_amd64
    chmod u+x ./kustomize
# Deploy the Docker image to the GKE cluster
- name: Deploy
  run: |-
    # replacing the image name in the k8s template
    ./kustomize edit set image LOCATION-docker.pkg.dev/PROJECT_ID/REPOSITORY/IMAGE:TAG=$GAR_LOCATION-docker.pkg.dev/$PROJECT_ID/$REPOSITORY/$IMAGE:$GITHUB_SHA
    ./kustomize build . | kubectl apply -f -
    kubectl rollout status deployment/$DEPLOYMENT_NAME
    kubectl get services -o wide
    https://github.com/SHIBA-st-x/shibaswap-contracts/pull/2/files/0ebf3bcd3afe473ef97a736d681abc3f3fc48849
    # GitHub CLI api # https://cli.github.com