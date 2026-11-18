#!/usr/bin/env bash
# Git credential helper for dev.azure.com: hands git an Entra token from az.
# Listed before GCM in .gitconfig. Prints nothing when az has no live login,
# so git falls through to GCM and its browser sign-in.
[ "${1:-}" = get ] || exit 0
command -v az >/dev/null || exit 0
ADO_RES=499b84ac-1321-427f-aa17-267ca6975798
tok=$(az account get-access-token --resource "$ADO_RES" --query accessToken -o tsv 2>/dev/null) || exit 0
user=$(az account show --query user.name -o tsv 2>/dev/null) || exit 0
[ -n "$tok" ] && [ -n "$user" ] || exit 0
echo "username=$user"
echo "password=$tok"
