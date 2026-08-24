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
      DATA api_rows TYPE zcl_call_api_ud_so_hdr=>tt_header.
      LOOP AT rows INTO DATA(row).
        APPEND VALUE #( Uuid = row-uuid SalesOrder = row-sales_order CustomerGroup = row-customer_group
          LcNumber = row-lc_number LcOpenDate = row-lc_open_date CommissionRate = row-commission_rate
          ExportTrustContract = row-export_trust_contract HasCustomerGroup = row-has_customer_group
          HasLcNumber = row-has_lc_number HasLcOpenDate = row-has_lc_open_date
          HasCommissionRate = row-has_commission_rate HasExportTrustContract = row-has_export_trust_contract ) TO api_rows.
      ENDLOOP.
      zcl_call_api_ud_so_hdr=>update_header( CHANGING ct_data = api_rows ).
      MODIFY ENTITIES OF zi_mch_so_file
        ENTITY DataFile
        UPDATE FIELDS ( MessageType Message )
        WITH VALUE #( FOR api_row IN api_rows
          ( Uuid = api_row-Uuid
            MessageType = api_row-MessageType
            Message = api_row-Message ) )
        FAILED DATA(update_failed)
        REPORTED DATA(update_reported).
      DATA(file_status) = COND #( WHEN line_exists( api_rows[ MessageType = 'E' ] )
                                  THEN 'E' ELSE 'D' ).
      DATA(file_message) = COND string( WHEN file_status = 'D'
        THEN `All Sales Orders were processed successfully`
        ELSE `Processing completed with errors` ).
      MODIFY ENTITIES OF zi_mch_so_file
        ENTITY ManageFile
        UPDATE FIELDS ( Status Message )
        WITH VALUE #( ( Uuid = rows[ 1 ]-uuid_file
                        Status = file_status
                        Message = file_message ) )
        FAILED DATA(file_failed)
        REPORTED DATA(file_reported).
      COMMIT ENTITIES.
    ENDLOOP.
  ENDMETHOD.

  METHOD if_apj_dt_exec_object~get_parameters.
    et_parameter_def = VALUE #( (
      selname = 'HDR_ID'
      kind = if_apj_dt_exec_object=>select_option
      datatype = 'C'
      length = 32
      param_text = 'Upload UUID'
      changeable_ind = abap_true ) ).
  ENDMETHOD.
ENDCLASS.
