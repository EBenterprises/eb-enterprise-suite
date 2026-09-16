import LegalDocument from "../LegalDocument";

export default function Copyright() {
  return (
    <LegalDocument
      label="LEGAL / COPYRIGHT"
      title="Copyright & Intellectual Property"
    >
      <p>
        © {new Date().getFullYear()} OMEGA®. All rights reserved.
      </p>

      <h2>OMEGA®</h2>
      <p>
        OMEGA®, its product identity, interface design, software architecture,
        documentation, visual systems, and associated proprietary materials
        are protected intellectual property to the extent provided by
        applicable law.
      </p>

      <h2>Trademarks</h2>
      <p>
        OMEGA® and associated marks may be trademarks or registered trademarks
        of their respective owner(s). Trademark status and ownership should
        always be represented accurately in jurisdiction-specific materials.
      </p>

      <h2>Third-party materials</h2>
      <p>
        Third-party names, trademarks, libraries, and technologies remain the
        property of their respective owners.
      </p>
    </LegalDocument>
  );
}
