CLASS zcl_job_mch_so_header DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_apj_dt_exec_object.
    INTERFACES if_apj_rt_exec_object.
ENDCLASS.

CLASS zcl_job_mch_so_header IMPLEMENTATION.
  METHOD if_apj_rt_exec_object~execute.
    LOOP AT it_parameters INTO DATA(parameter).
      SELECT * FROM ztb_mch_so_hdr
        WITH PRIVILEGED ACCESS
        WHERE uuid_file = @parameter-low
          AND message_type = 'J'
        INTO TABLE @DATA(rows).
      CHECK rows IS NOT INITIAL.
      DATA api_rows TYPE zcl_call_api_ud_so=>tt_header.
      LOOP AT rows INTO DATA(row).
        APPEND VALUE #( Uuid = row-uuid SalesOrder = row-sales_order CustomerGroup = row-customer_group
          LcNumber = row-lc_number LcOpenDate = row-lc_open_date CommissionRate = row-commission_rate
          ExportTrustContract = row-export_trust_contract HasCustomerGroup = row-has_customer_group
          HasLcNumber = row-has_lc_number HasLcOpenDate = row-has_lc_open_date
          HasCommissionRate = row-has_commission_rate HasExportTrustContract = row-has_export_trust_contract ) TO api_rows.
      ENDLOOP.
      zcl_call_api_ud_so=>update_header( CHANGING ct_data = api_rows ).
      LOOP AT api_rows INTO DATA(api_row).
        UPDATE ztb_mch_so_hdr SET message_type = @api_row-MessageType message = @api_row-Message
          WHERE uuid = @api_row-Uuid AND uuid_file = @parameter-low.
      ENDLOOP.
      COMMIT WORK.
    ENDLOOP.
  ENDMETHOD.

  METHOD if_apj_dt_exec_object~get_parameters.
  ENDMETHOD.
ENDCLASS.
