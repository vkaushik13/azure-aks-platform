#!/usr/bin/env python3
"""
AKS Platform Health Check Script
Checks cluster health, node status, and critical workload availability.
Author: Varun Kaushik | github.com/vkaushik13
"""

import subprocess
import json
import sys
from datetime import datetime


def run_kubectl(args: list) -> dict:
    """Run a kubectl command and return parsed JSON output."""
    cmd = ["kubectl"] + args + ["-o", "json"]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERROR: {result.stderr}")
        sys.exit(1)
    return json.loads(result.stdout)


def check_nodes() -> bool:
    """Check all nodes are Ready."""
    nodes = run_kubectl(["get", "nodes"])
    all_ready = True
    print("\n=== NODE STATUS ===")
    for node in nodes["items"]:
        name = node["metadata"]["name"]
        conditions = {c["type"]: c["status"] for c in node["status"]["conditions"]}
        ready = conditions.get("Ready") == "True"
        status = "✅ Ready" if ready else "❌ NotReady"
        print(f"  {name}: {status}")
        if not ready:
            all_ready = False
    return all_ready


def check_system_pods() -> bool:
    """Check system namespace pods are running."""
    namespaces = ["kube-system", "monitoring", "ingress-nginx", "cert-manager"]
    all_healthy = True
    print("\n=== SYSTEM PODS ===")
    for ns in namespaces:
        pods = run_kubectl(["get", "pods", "-n", ns])
        not_running = [
            p["metadata"]["name"]
            for p in pods["items"]
            if p["status"].get("phase") not in ["Running", "Succeeded"]
        ]
        if not_running:
            print(f"  {ns}: ❌ Unhealthy pods: {', '.join(not_running)}")
            all_healthy = False
        else:
            count = len(pods["items"])
            print(f"  {ns}: ✅ {count} pods healthy")
    return all_healthy


def check_persistent_volumes() -> bool:
    """Check PVCs are bound."""
    pvcs = run_kubectl(["get", "pvc", "--all-namespaces"])
    unbound = [
        f"{p['metadata']['namespace']}/{p['metadata']['name']}"
        for p in pvcs["items"]
        if p["status"]["phase"] != "Bound"
    ]
    print("\n=== PERSISTENT VOLUMES ===")
    if unbound:
        print(f"  ❌ Unbound PVCs: {', '.join(unbound)}")
        return False
    print(f"  ✅ All PVCs bound ({len(pvcs['items'])} total)")
    return True


def main():
    print(f"AKS Platform Health Check — {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)

    results = {
        "nodes": check_nodes(),
        "system_pods": check_system_pods(),
        "persistent_volumes": check_persistent_volumes(),
    }

    print("\n=== SUMMARY ===")
    all_passed = all(results.values())
    for check, passed in results.items():
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"  {check}: {status}")

    print("\n" + ("✅ All checks passed" if all_passed else "❌ Some checks failed"))
    sys.exit(0 if all_passed else 1)


if __name__ == "__main__":
    main()
