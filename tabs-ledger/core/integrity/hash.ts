import { createHash } from "node:crypto";
import { stableStringify } from "../serialization/json";

export function sha256(value: unknown) {
  return createHash("sha256")
    .update(stableStringify(value))
    .digest("hex");
}
