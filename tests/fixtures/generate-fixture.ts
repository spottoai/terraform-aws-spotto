// Regenerates spotto-aws-setup-current.json with the real API bundle builder (sibling ../api checkout).
// Purposes use the portal's canonical order so the configuration round-trips through the portal draft.
// Run from ../api: node_modules/.bin/esbuild ../terraform-aws-spotto/tests/fixtures/generate-fixture.ts --bundle --platform=node --format=cjs --outfile=/tmp/generate-fixture.cjs && node /tmp/generate-fixture.cjs ../terraform-aws-spotto/tests/fixtures/spotto-aws-setup-current.json
import { writeFileSync } from 'node:fs';
import { AwsIamOnboardingBundleBuilder } from '../../../api/services/CloudAccounts/AwsIamOnboardingBundleBuilder';

const companyId = 'company-example';
const estateId = 'estate-example';
const externalId = 'spotto-0f1e2d3c-4b5a-6978-8796-a5b4c3d2e1f0';
const management = '111122223333';
const storage = '000011112222';
const member = '444455556666';
const disabled = '777788889999';
const builder = new AwsIamOnboardingBundleBuilder('arn:aws:iam::999900001111:role/SpottoEngine');
const roleArn = (id: string) => `arn:aws:iam::${id}:role/SpottoReadOnlyRole`;

const exportDefinition = {
  type: 'DATA_EXPORTS' as const,
  exportArn: `arn:aws:bcm-data-exports:us-east-1:${management}:export/example-cur2-0123` as const,
  exportName: 'example-cur2',
  destination: {
    bucketName: 'example-cost-exports',
    basePrefix: 'cur2',
    region: 'us-east-1',
    bucketOwnerAccountId: storage,
    kmsKeyArn: `arn:aws:kms:us-east-1:${storage}:key/11111111-2222-3333-4444-555555555555`,
  },
};

const account = (accountId: string, name: string, purposes: string[], enabled = true) => ({
  schemaVersion: 1, companyId, estateId, accountId, roleArn: roleArn(accountId), name, purposes, enabled,
});

const configuration = {
  schemaVersion: 1,
  provider: 'AWS',
  companyId,
  updatedAt: '2026-10-06T00:00:00.000Z',
  estates: [
    {
      schemaVersion: 1, companyId, estateId, name: 'Example organization', kind: 'organization', enabled: true,
      organization: {
        schemaVersion: 1, companyId, estateId, organizationId: 'o-example12345', managementAccountId: management,
        accountSource: 'manual', roleDeploymentMode: 'customer-managed', excludedAccounts: [],
      },
      accounts: [
        account(management, 'Management', ['resource-discovery', 'commitments-planning', 'billing-definition']),
        account(storage, 'Billing storage', ['resource-discovery', 'billing-storage']),
        account(member, 'Workload', ['resource-discovery']),
        account(disabled, 'Retired', ['resource-discovery'], false),
      ],
      billingSources: [
        {
          schemaVersion: 1, companyId, estateId, billingSourceId: 'billing-example', name: 'Example CUR 2.0',
          definitionRoleAccountId: management, payerAccountId: management, storageRoleAccountId: storage,
          export: exportDefinition, coverage: { type: 'estate' }, enabled: true,
        },
      ],
    },
  ],
};

const setup = (rolePurposes: string[], billingSources?: unknown[]) => ({
  provider: 'AWS',
  externalId,
  createdAt: '2026-10-06T00:00:00.000Z',
  onboardingBundle: builder.build(externalId, { rolePurposes, ...(billingSources ? { billingSources } : {}) } as never),
});

const pkg = {
  kind: 'spotto.aws.setup',
  schemaVersion: 1,
  companyId,
  configuration,
  roles: [
    { accountId: management, roleArn: roleArn(management),
      setup: setup(['resource-discovery', 'commitments-planning', 'billing-definition'], [{ accessPurposes: ['billing-definition'], export: exportDefinition }]) },
    { accountId: storage, roleArn: roleArn(storage),
      setup: setup(['resource-discovery', 'billing-storage'], [{ accessPurposes: ['billing-storage'], export: exportDefinition, dataExportName: 'example-cur2' }]) },
    { accountId: member, roleArn: roleArn(member), setup: setup(['resource-discovery']) },
  ],
};

writeFileSync(process.argv[2]!, `${JSON.stringify(pkg, null, 2)}\n`);
