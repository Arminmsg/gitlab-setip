
resource "vault_jwt_auth_backend" "gitlab" {
  description  = "JWT auth backend for Gitlab-CI pipeline"
  path         = "gitlab_jwt"
  jwks_url     = "https://gitlab.com/-/jwks"
  tune {
    listing_visibility = "unauth"
    default_lease_ttl  = var.gitlab_default_lease_ttl
    max_lease_ttl      = var.gitlab_max_lease_ttl
  }
}

resource "vault_policy" "pipeline-policy" {
  name = "pipeline-policy"

  policy = <<EOT
path "kv/test" {
  capabilities = ["read"]
}

path "kv/data/test" {
  capabilities = ["read"]
}
EOT
}

resource "vault_jwt_auth_backend_role" "pipeline" {
  backend   = vault_jwt_auth_backend.gitlab.path
  role_type = "jwt"

  role_name      = "app-pipeline"
  token_policies = ["default", "pipeline-policy"]

  bound_claims = {
    project_id = data.gitlab_project.vault.id
    ref        = "main"
    ref_type   = "branch"
    environment = ""
  }

  user_claim = "iss" 
  # Need to define what we want here

}

resource "vault_mount" "secret-mount" {
  path        = "kv"
  type        = "kv-v2"
  description = "KV Secrets engine"
}
