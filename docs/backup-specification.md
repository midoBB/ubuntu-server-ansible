# Offsite Backup System Specification

## 1. Executive Summary

This specification outlines a comprehensive backup solution for critical infrastructure components (Vault, PostgreSQL, MinIO) with automated offsite replication to both a NAS device and Google Drive using Restic as the backup tool with deduplication and encryption capabilities.

## 2. Architecture Overview

### 2.1 Components

- **Backup Orchestrator**: Systemd timers/services running as the `deploy` user
- **Restic**: Primary backup tool providing encryption, deduplication, and incremental backups
- **Rclone**: Bridge for cloud storage integration (Google Drive)
- **Vault Agent**: Provides credentials for backup operations
- **Local Staging**: Temporary storage for backup preparation
- **Remote Targets**: NAS (SSH/SFTP) and Google Drive (via rclone)

### 2.2 Data Flow

```
[Service] → [Local Backup] → [Staging] → [Restic] → [Remote Storage]
                                ↓
                          [Vault Agent]
                          (credentials)
```

### 2.3 Security Model

- All backups encrypted at rest using Restic's built-in encryption
- Backup credentials stored in Vault and retrieved via Vault Agent
- SSH key-based authentication for NAS access
- Application specific credentials stored in Vault for authentication for Google Drive via rclone
- Backup scripts run as `backup` user with minimal privileges

## 3. Backup Sources

### 3.1 Vault Backup

- **Method**: `vault operator raft snapshot save`
- **Frequency**: Daily at 1 AM
- **Pre-backup**: Health check via API
- **Post-backup**: Verify snapshot integrity
- **Estimated size**: ~100MB per snapshot

### 3.2 PostgreSQL Backup

- **Method**: `podman exec` with `pg_dumpall`
- **Frequency**: Daily at 2 AM
- **Pre-backup**: Check container health
- **Post-backup**: Test restore to temporary database
- **Compression**: gzip -9
- **Estimated size**: Variable, likely <1GB compressed

### 3.3 MinIO Backup

- **Method**: `mc mirror` with exclusions
- **Frequency**: Daily at 3 AM
- **Pre-backup**: Sync policy review
- **Post-backup**: Verify object count
- **Compression**: Tar + gzip for changed objects
- **Estimated size**: Variable based on stored objects

## 4. Backup Destinations

### 4.1 NAS Configuration

- **Protocol**: SSH/SFTP
- **Authentication**: Ed25519 SSH key
- **Path structure**: `/backups/homeserver/{vault,postgres,minio}/{date}/`
- **Network**: Accessible via Tailscale VPN
- **Bandwidth limit**: 10MB/s to avoid saturation

### 4.2 Google Drive Configuration

- **Integration**: Via rclone backend
- **Authentication**: Service account with OAuth2
- **Path structure**: `Backups/homeserver/{vault,postgres,minio}/{date}/`
- **API limits**: Respect 750GB/day upload quota
- **Chunking**: 100MB chunks for large files

## 5. Retention Policy

### 5.1 Offsite Retention

- **Daily backups**: Keep 7 most recent
- **Monthly backups**: Keep 12 most recent (first backup of each month)
- **Yearly backups**: Keep 2 most recent (first backup of each year)

### 5.2 Pruning Schedule

- Run weekly on Sundays at 4 AM
- Verify at least 3 backups exist before pruning
- Log all pruning operations

## 6. Monitoring & Alerting

### 6.1 Health Checks

- Backup job completion status
- Remote storage availability
- Backup size anomalies (>50% change)
- Restore test results

### 6.2 Metrics to Track

- Backup duration
- Data transferred
- Storage utilization
- Deduplication ratio
- Encryption/compression ratios

### 6.3 Alerting Channels

- Systemd journal logs
- Email notifications for failures
- Prometheus metrics export (future)

## 7. Restore Procedures

### 7.1 Restore Priority

1. Vault (highest - contains all secrets)
2. PostgreSQL (application data)
3. MinIO (object storage)

### 7.2 Restore Testing

- Monthly automated restore tests to staging environment
- Quarterly manual disaster recovery drills
- Document restore times for capacity planning

## 8. Development Stories

### Story 1: Backup Infrastructure Setup

**As a** system administrator
**I want** to install and configure backup tools
**So that** I have the foundation for automated backups

**Acceptance Criteria:**

- [ ] Restic installed via Ansible role
- [ ] Rclone installed and configured
- [ ] Backup user permissions configured
- [ ] Local staging directory structure created
- [ ] Systemd timer/service templates ready

**Tasks:**

- Create `backup` Ansible role
- Install Restic and rclone packages
- Create backup directory structure
- Set up logging configuration

---

### Story 2: Vault Backup Implementation

**As a** system administrator
**I want** automated Vault backups
**So that** I can recover from Vault data loss

**Acceptance Criteria:**

- [ ] Vault snapshot script created
- [ ] Systemd timer daily at 1 AM
- [ ] Snapshots validated after creation
- [ ] Backup credentials stored in Vault
- [ ] Health checks before backup

**Tasks:**

- Create vault-backup.sh script
- Implement snapshot validation
- Create systemd service/timer
- Add Vault API health checks
- Store backup encryption key in Vault

---

### Story 3: PostgreSQL Backup Implementation

**As a** system administrator
**I want** automated PostgreSQL backups
**So that** I can recover database data

**Acceptance Criteria:**

- [ ] pg_dump script handles all databases
- [ ] Compression reduces backup size by >70%
- [ ] Systemd timer runs daily at 2 AM
- [ ] Test restore validates backup
- [ ] Connection via container network

**Tasks:**

- Create postgres-backup.sh script
- Implement backup compression
- Add restore validation
- Configure systemd scheduling
- Handle container connectivity

---

### Story 4: MinIO Backup Implementation

**As a** system administrator
**I want** incremental MinIO backups
**So that** I can efficiently backup object storage

**Acceptance Criteria:**

- [ ] mc mirror syncs only changed objects
- [ ] Metadata preserved in backups
- [ ] Exclusion patterns configured
- [ ] Bandwidth limiting implemented
- [ ] Object count verification

**Tasks:**

- Create minio-backup.sh script
- Configure mc alias for local MinIO
- Implement incremental sync logic
- Add bandwidth limiting
- Create verification process

---

### Story 5: NAS Backup Destination

**As a** system administrator
**I want** to backup to NAS storage
**So that** I have local network backups

**Acceptance Criteria:**

- [ ] SSH key authentication configured
- [ ] Restic repository initialized on NAS
- [ ] Network connectivity via Tailscale
- [ ] Bandwidth limiting active
- [ ] Repository health monitoring

**Tasks:**

- Generate and deploy SSH keys
- Initialize Restic repository
- Configure Tailscale networking
- Implement bandwidth limits
- Add connectivity checks

---

### Story 6: Google Drive Integration

**As a** system administrator
**I want** to backup to Google Drive
**So that** I have cloud-based backups

**Acceptance Criteria:**

- [ ] Rclone configured with service account
- [ ] Restic repository initialized
- [ ] Chunked uploads for large files
- [ ] API quota monitoring
- [ ] Encryption keys backed up separately

**Tasks:**

- Create Google Cloud service account
- Configure rclone with OAuth2
- Initialize Restic repository
- Implement chunk size optimization
- Add quota monitoring

---

### Story 7: Retention Policy Implementation

**As a** system administrator
**I want** automated backup retention
**So that** storage is efficiently utilized

**Acceptance Criteria:**

- [ ] Restic forget runs weekly
- [ ] Policy keeps 7 daily + 12 monthly
- [ ] Prune only after verification
- [ ] Logging of all deletions
- [ ] Storage metrics updated

**Tasks:**

- Create retention script
- Implement safety checks
- Configure systemd scheduling
- Add deletion logging
- Update storage metrics

---

### Story 8: Monitoring and Alerting

**As a** system administrator
**I want** backup monitoring and alerts
**So that** I know when backups fail

**Acceptance Criteria:**

- [ ] All backup jobs report status
- [ ] Email alerts for failures
- [ ] Backup size tracking
- [ ] Dashboard for backup status
- [ ] Restore test reporting

**Tasks:**

- Implement status reporting
- Configure email notifications
- Create metrics collection
- Build status dashboard
- Add restore test automation

---

### Story 9: Restore Automation

**As a** system administrator
**I want** automated restore testing
**So that** I can verify backup integrity

**Acceptance Criteria:**

- [ ] Monthly automated restore tests
- [ ] Restore to isolated environment
- [ ] Validation of restored data
- [ ] Performance metrics collected
- [ ] Failure notifications

**Tasks:**

- Create restore test framework
- Implement data validation
- Configure test scheduling
- Add performance tracking
- Document restore procedures

---

### Story 10: Disaster Recovery Documentation

**As a** system administrator
**I want** comprehensive DR documentation
**So that** anyone can perform recovery

**Acceptance Criteria:**

- [ ] Step-by-step restore guides
- [ ] Architecture diagrams included
- [ ] Credential recovery documented
- [ ] RTO/RPO clearly defined
- [ ] Regular review process

**Tasks:**

- Write restore procedures
- Create architecture diagrams
- Document credential management
- Define RTO/RPO targets
- Establish review schedule

## 9. Implementation Phases

### Phase 1: Foundation (Stories 1-2)

- Set up backup infrastructure
- Implement Vault backups as proof of concept

### Phase 2: Service Backups (Stories 3-4)

- Add PostgreSQL backup capability
- Add MinIO backup capability

### Phase 3: Offsite Storage (Stories 5-6)

- Configure NAS destination
- Configure Google Drive destination

### Phase 4: Operations (Stories 7-10)

- Implement retention policies
- Add monitoring and alerting
- Create restore automation
- Complete documentation

## 10. Success Criteria

- **RTO (Recovery Time Objective)**: < 4 hours for full restoration
- **RPO (Recovery Point Objective)**: < 24 hours data loss maximum
- **Backup Success Rate**: > 99.5%
- **Storage Efficiency**: > 10:1 deduplication ratio
- **Restore Validation**: 100% monthly test success

## 11. Future Enhancements

- **Additional Destinations**: S3-compatible cloud storage
- **Application-aware Backups**: Pre/post backup hooks for applications
- **Incremental File Backups**: Backup select configuration files
- **Centralized Monitoring**: Integration with Prometheus/Grafana
- **Multi-site Replication**: Cross-region backup distribution
