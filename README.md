# mass_c_sale_order_header

RAP-based mass change for Sales Order header data.

## Input template

The first worksheet must contain two header rows and data beginning at row 4:

| SO* | Customer Group | SO Text |  |  |  |
|---|---|---|---|---|---|
|  |  | Số LC | Ngày mở LC | Tỷ lệ chi com | Số hợp đồng ủy thác XK |

`SO*` is mandatory. Blank cells mean that the corresponding field is not changed.
The Z015 column is preserved as text because it is written to Sales Order long text and may contain units or notes.

## Design

One upload is a file root persisted in `ZTB_MCH_SO_FILE`; every Sales Order Header row in that file is persisted in
`ZTB_MCH_SO_HDR` with the same `UUID_FILE`. The rows are exposed through `ZI_MCH_SO_HDR` / `ZC_MCH_SO_HDR` and are
processed together as one upload unit, matching the reference repository's file/detail pattern.
The behavior pool validates the template and creates all detail rows through `CREATE BY _DataFile`.
The `PostConfirm` action marks all rows for background processing. The RAP additional-save implementation schedules
`ZCL_JOB_MCH_SO_HEADER`, and the Sales Order update is isolated in `ZCL_CALL_API_UD_SO_HDR`. The original attachment
is persisted on the file root, following the `zabs_file_crud_poc` upload pattern from the reference repository.

## Required SAP API mapping

- Customer Group: Sales Order header API field `CustomerGroup`.
- Số LC, Ngày mở LC, Tỷ lệ chi com, Số hợp đồng ủy thác XK: Sales Order header text IDs `Z013`, `Z014`, `Z015`, `Z011`.

The text update adapter uses PATCH/POST upsert semantics with the released Sales Order API or a Tier-3 wrapper if the
target S/4HANA release does not release header text maintenance directly.

## RAP/OData artifacts

- Root/child interface views: `ZI_MCH_SO_FILE`, `ZI_MCH_SO_HDR`.
- Root/child projection views: `ZC_MCH_SO_FILE`, `ZC_MCH_SO_HDR`.
- Static action: `uploadExcel` with parameter `zabs_file_crud_poc`.
- OData V4 service: `ZSD_MCH_SO_FILE` and binding `ZUI_MCH_SO_FILE`.
- Application-job class/template for rows marked `J`.
