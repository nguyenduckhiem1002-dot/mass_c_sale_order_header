# Implementation notes

The implementation follows the file/detail RAP pattern from `mass_c_sale_order`, with one upload root and multiple Sales Order header rows.

Before activation in ADT:

1. Import through abapGit and regenerate the four DDIC table serializers in ADT if the target release uses a different TABL serializer version.
2. Confirm communication arrangement/API alias `API_SALES_ORDER_V2` and text language `EN` in the target tenant.
3. Confirm text IDs `Z013`, `Z014`, `Z015`, `Z011` are configured for Sales Order headers.
4. Replace the permissive global authorization implementation with the project's IAM authorization policy.
5. Run ADT activation and ATC Cloud Readiness in the target SAP system.
