# Ansible Check Mode Issues and Solutions

## Overview
This document describes known issues when running Ansible playbooks in check mode (`--check`) and their solutions.

## LVM Module Size Calculation in Check Mode

### Issue
The `ansible.posix.lvol` module fails in check mode when creating a new logical volume:
```
TASK [monitoring_common : Create logical volume for Docker data]
fatal: [HOST]: FAILED! => {"msg": "Sorry, no shrinking of docker to 0 permitted."}
```

### Root Cause
When a logical volume doesn't exist and check mode is enabled, the `lvol` module cannot determine the current size, defaulting to 0. If the task specifies a size parameter, the module interprets this as attempting to shrink from 0 to the target size, which is invalid.

### Solutions

**Option 1: Skip Storage Tasks During Dry-Run**
```bash
ansible-playbook playbook.yml --check --diff --skip-tags storage,lvm
```

**Option 2: Disable Check Mode for LVM Tasks**
```yaml
- name: Create logical volume for Docker data
  ansible.posix.lvol:
    vg: vg_data
    lv: lv_docker
    size: 50G
  check_mode: false  # Always run this task, even in check mode
```

**Option 3: Make LVM Tasks Conditional**
```yaml
- name: Create logical volume for Docker data
  ansible.posix.lvol:
    vg: vg_data
    lv: lv_docker
    size: 50G
  when: not ansible_check_mode
```

### Recommendation
For infrastructure playbooks that manage storage, use **Option 1** for dry-runs. For production roles, use **Option 2** if the LVM operation is idempotent and safe to execute during check mode.

---

## URI Module Registered Variables in Check Mode

### Issue
Tasks that check the status of a URI/API request fail when the URI module skips execution in check mode:
```
TASK [graylog : If POST failed, fetch existing pipeline rules]
fatal: [HOST]: FAILED! => {"msg": "Error while evaluating conditional: object of type 'dict' has no attribute 'status'"}
```

### Root Cause
The `ansible.builtin.uri` module skips execution in check mode by default. When a subsequent task checks `registered_var.status`, the attribute doesn't exist because the request was never made.

### Solutions

**Option 1: Safe Conditional Checking**
```yaml
- name: Attempt to create resource (POST)
  ansible.builtin.uri:
    url: "{{ api_url }}"
    method: POST
    body: "{{ payload }}"
  register: api_post_result
  failed_when: false

- name: If POST failed, handle error
  ansible.builtin.uri:
    url: "{{ api_url }}/list"
    method: GET
  register: existing_resources
  when:
    - api_post_result is defined
    - api_post_result.status is defined
    - api_post_result.status not in [200, 201]
```

**Option 2: Default Value**
```yaml
- name: If POST failed, handle error
  ansible.builtin.uri:
    url: "{{ api_url }}/list"
    method: GET
  when: (api_post_result.status | default(999)) not in [200, 201]
```

**Option 3: Force URI Execution in Check Mode**
```yaml
- name: Attempt to create resource (POST)
  ansible.builtin.uri:
    url: "{{ api_url }}"
    method: POST
    body: "{{ payload }}"
  register: api_post_result
  check_mode: false  # Execute even in check mode
  failed_when: false
```

### Recommendation
Use **Option 1** for most cases to maintain check mode safety. Use **Option 3** only for GET requests that don't modify state.

---

## Best Practices for Check Mode Compatibility

1. **Always test registered variables before accessing attributes**:
   ```yaml
   when: my_var is defined and my_var.status is defined
   ```

2. **Use `default()` filter for safe attribute access**:
   ```yaml
   when: (my_var.status | default(0)) == 200
   ```

3. **Tag tasks appropriately** for selective execution:
   ```yaml
   - name: Create LVM
     ansible.posix.lvol: ...
     tags: [storage, lvm]
   ```

4. **Document check mode limitations** in role README:
   ```markdown
   ## Check Mode Limitations
   - Storage tasks require `--skip-tags storage` when using `--check`
   - API validation tasks will be skipped in check mode
   ```

5. **Use `changed_when: false`** for read-only operations:
   ```yaml
   - name: Check API status
     ansible.builtin.uri:
       url: "{{ api_url }}/health"
     register: health_check
     changed_when: false
     check_mode: false
   ```

---

## Related Modules with Check Mode Limitations

| Module | Issue | Solution |
|--------|-------|----------|
| `ansible.posix.lvol` | Size calculation fails for non-existent LVs | Disable check mode or skip with tags |
| `ansible.builtin.uri` | Skips execution, no status in registered var | Use safe conditionals or `check_mode: false` for GETs |
| `ansible.builtin.shell` | Command never executes | Use `creates:` parameter or `changed_when:` |
| `community.docker.docker_container` | May report false changes | Expected behavior; verify with `--diff` |

---

## Testing Check Mode Compatibility

```bash
# Test with check mode
ansible-playbook site.yml --check --diff -i inventory/hosts.yml

# Test with check mode, skipping storage
ansible-playbook site.yml --check --diff -i inventory/hosts.yml --skip-tags storage,lvm

# Test specific role with check mode
ansible-playbook test_role.yml --check --diff -e role_under_test=monitoring_backup
```
