import { getDb, transaction } from "@/database/db";
import {
  createLedgerEntry,
  customerTotals
} from "@/database/repositories/ledger";
import { getCustomer } from "@/database/repositories/customers";
import { audit } from "./audit";
import type { LedgerKind } from "@/types/domain";

export function recordLedgerEntry(input: {
  organizationId: string;
  customerId: string;
  kind: LedgerKind;
  amountCents: number;
  quantityText?: string | null;
  item?: string | null;
  location?: string | null;
  description?: string | null;
  effectiveAt?: string;
  source?: string;
  sourceReference?: string | null;
  metadata?: Record<string, unknown>;
  actor?: string;
}) {
  return transaction(() => {
    const db = getDb();

    const customer =
      getCustomer(db, input.customerId);

    if (!customer) {
      throw new Error("Customer not found.");
    }

    if (
      customer.organizationId !==
      input.organizationId
    ) {
      throw new Error(
        "Customer organization mismatch."
      );
    }

    const entry = createLedgerEntry(db, {
      ...input,
      effectiveAt:
        input.effectiveAt ??
        new Date().toISOString()
    });

    audit(db, {
      organizationId: input.organizationId,
      entityType: "ledger_entry",
      entityId: entry.id,
      action: "created",
      actor: input.actor,
      payload: entry
    });

    return entry;
  });
}

export function getCustomerBalance(
  customerId: string
) {
  return customerTotals(
    getDb(),
    customerId
  );
}
