# Implementation notes

The GitHub target repository was public but empty. The reference repository was readable and confirmed the RAP upload pattern, but the execution environment could not clone or push over GitHub TLS and the browser session was signed out. Therefore this is a local, reviewable RAP scaffold, committed on a local branch; it is not represented as pushed or production-ready.

Before activation in ADT:

1. Replace the illustrative table XML field declarations with the exact ADT serializer format used by the target system.
2. Reuse the concrete `zabs_file_crud_poc` file root/artifacts and add the four header-specific columns to its upload detail or use `ZTB_MCH_SO_HDR` as the detail table.
3. Implement `ZCL_MCH_SO_HDR_UPDATE` against released Sales Order APIs for the system release; validate text IDs `Z013`, `Z014`, `Z015`, `Z011` and authorization behavior.
4. Add the service definition/binding and application job artifact following the reference repo naming convention.
5. Run ATC Cloud Readiness and abaplint in ADT; the table XML is intentionally a source placeholder because ADT table serialization is system-specific.
