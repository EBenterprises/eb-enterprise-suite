import LegalDocument from "../LegalDocument";

export default function Terms() {
  return (
    <LegalDocument
      label="LEGAL / TERMS"
      title="Terms of Service"
    >
      <p>
        These terms define the framework for use of the OMEGA® platform,
        including accounts, workspaces, generated outputs, security,
        acceptable use, and service operation.
      </p>

      <h2>Use of the platform</h2>
      <p>
        You are responsible for activity performed through your account and
        for maintaining the confidentiality of your authentication
        credentials.
      </p>

      <h2>Generated output</h2>
      <p>
        OMEGA® generates computational results based on supplied objectives,
        constraints, available runtime capabilities, and configured systems.
        Generated output should be reviewed before being used in consequential
        applications.
      </p>

      <h2>Acceptable use</h2>
      <p>
        The platform must not be used for unlawful activity, abuse of the
        service, unauthorized access, or attempts to compromise other users or
        systems.
      </p>

      <h2>Service evolution</h2>
      <p>
        OMEGA® may evolve its architecture, interfaces, capabilities, and
        supporting infrastructure as the platform develops.
      </p>
    </LegalDocument>
  );
}
