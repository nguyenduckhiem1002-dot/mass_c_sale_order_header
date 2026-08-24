# mass_c_sale_order_header

RAP-based mass change for Sales Order header data.

## Input template

The first worksheet must contain two header rows and data beginning at row 4:

| SO* | Customer Group | SO Text |  |  |  |
|---|---|---|---|---|---|
|  |  | Số LC | Ngày mở LC | Tỷ lệ chi com | Số hợp đồng ủy thác XK |

`SO*` is mandatory. Blank cells mean that the corresponding field is not changed.
The percentage column accepts decimal values (`0.015`) and percentage text (`1%`).

## Design

One upload is a file root persisted in `ZTB_MCH_SO_FILE`; every Sales Order Header row in that file is persisted in
`ZTB_MCH_SO_HDR` with the same `UUID_FILE`. The rows are exposed through `ZI_MCH_SO_HDR` / `ZC_MCH_SO_HDR` and are
processed together as one upload unit, matching the reference repository's file/detail pattern.
The behavior pool validates the template and schedules the processing job after upload completion.
The actual Sales Order update is isolated in `ZCL_MCH_SO_HDR_UPDATE`, allowing the released RAP/API implementation
to be substituted without changing the upload model. The file lifecycle follows the existing `zabs_file_crud_poc`
pattern used by the reference repository.

## Required SAP API mapping

- Customer Group: Sales Order header API field `CustomerGroup`.
- Số LC, Ngày mở LC, Tỷ lệ chi com, Số hợp đồng ủy thác XK: Sales Order header text IDs `Z013`, `Z014`, `Z015`, `Z011`.

The text update adapter must use a released Sales Order API or a Tier-3 wrapper if the target S/4HANA release does not
release header text maintenance directly.
