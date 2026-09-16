export type LedgerKind =
  | "charge"
  | "payment"
  | "credit"
  | "adjustment"
  | "reversal";

export type CustomerStatus =
  | "active"
  | "archived";

export interface Customer {
  id: string;
  organizationId: string;
  displayName: string;
  status: CustomerStatus;
  metadata: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}

export interface LedgerEntry {
  id: string;
  organizationId: string;
  customerId: string;
  kind: LedgerKind;
  amountCents: number;
  quantityText: string | null;
  item: string | null;
  location: string | null;
  description: string | null;
  effectiveAt: string;
  createdAt: string;
  source: string;
  sourceReference: string | null;
  metadata: Record<string, unknown>;
  reversedEntryId: string | null;
}
