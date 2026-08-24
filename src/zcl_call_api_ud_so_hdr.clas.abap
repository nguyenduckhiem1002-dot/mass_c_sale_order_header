CLASS zcl_call_api_ud_so_hdr DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES BEGIN OF ty_header.
    TYPES Uuid TYPE sysuuid_x16.
    TYPES SalesOrder TYPE c LENGTH 10.
    TYPES CustomerGroup TYPE c LENGTH 2.
    TYPES LcNumber TYPE string.
    TYPES LcOpenDate TYPE d.
    TYPES CommissionRate TYPE string.
    TYPES ExportTrustContract TYPE string.
    TYPES HasCustomerGroup TYPE abap_boolean.
    TYPES HasLcNumber TYPE abap_boolean.
    TYPES HasLcOpenDate TYPE abap_boolean.
    TYPES HasCommissionRate TYPE abap_boolean.
    TYPES HasExportTrustContract TYPE abap_boolean.
    TYPES MessageType TYPE c LENGTH 1.
    TYPES Message TYPE string.
    TYPES END OF ty_header.
    TYPES tt_header TYPE STANDARD TABLE OF ty_header WITH EMPTY KEY.
    CLASS-METHODS update_header CHANGING ct_data TYPE tt_header.
  PRIVATE SECTION.
    CONSTANTS c_service_root TYPE string VALUE `/sap/opu/odata/sap/API_SALES_ORDER_SRV/`.
    CONSTANTS c_api_name TYPE string VALUE `API_SALES_ORDER_V2`.
    CONSTANTS c_max_message TYPE i VALUE 255.
    CLASS-METHODS do_call IMPORTING iv_endpoint TYPE string iv_method TYPE string iv_body TYPE string OPTIONAL
      EXPORTING ev_code TYPE i ev_response TYPE string ev_message TYPE string RETURNING VALUE(rv_ok) TYPE abap_bool.
    CLASS-METHODS update_customer_group IMPORTING is_data TYPE ty_header EXPORTING ev_message TYPE string
      RETURNING VALUE(rv_ok) TYPE abap_bool.
    CLASS-METHODS update_header_text IMPORTING is_data TYPE ty_header iv_text_id TYPE string iv_text TYPE string
      EXPORTING ev_message TYPE string RETURNING VALUE(rv_ok) TYPE abap_bool.
    CLASS-METHODS error_text IMPORTING iv_response TYPE string RETURNING VALUE(rv_message) TYPE string.
    CLASS-METHODS escape_json IMPORTING iv_text TYPE string RETURNING VALUE(rv_text) TYPE string.
ENDCLASS.

CLASS zcl_call_api_ud_so_hdr IMPLEMENTATION.
  METHOD update_header.
    LOOP AT ct_data ASSIGNING FIELD-SYMBOL(<row>).
      DATA errors TYPE string_table.
      IF <row>-has_customer_group = abap_true.
        update_customer_group( EXPORTING is_data = <row> IMPORTING ev_message = DATA(message)
          RECEIVING rv_ok = DATA(ok) ).
        IF ok = abap_false. APPEND message TO errors. ENDIF.
      ENDIF.
      IF <row>-has_lc_number = abap_true.
        update_header_text( EXPORTING is_data = <row> iv_text_id = 'Z013' iv_text = <row>-lc_number
          IMPORTING ev_message = message RECEIVING rv_ok = ok ).
        IF ok = abap_false. APPEND |Số LC: { message }| TO errors. ENDIF.
      ENDIF.
      IF <row>-has_lc_open_date = abap_true.
        update_header_text( EXPORTING is_data = <row> iv_text_id = 'Z014'
          iv_text = |{ <row>-lc_open_date DATE = ISO }| IMPORTING ev_message = message RECEIVING rv_ok = ok ).
        IF ok = abap_false. APPEND |Ngày mở LC: { message }| TO errors. ENDIF.
      ENDIF.
      IF <row>-has_commission_rate = abap_true.
        update_header_text( EXPORTING is_data = <row> iv_text_id = 'Z015'
          iv_text = |{ <row>-commission_rate }| IMPORTING ev_message = message RECEIVING rv_ok = ok ).
        IF ok = abap_false. APPEND |Tỷ lệ chi com: { message }| TO errors. ENDIF.
      ENDIF.
      IF <row>-has_export_trust_contract = abap_true.
        update_header_text( EXPORTING is_data = <row> iv_text_id = 'Z011' iv_text = <row>-export_trust_contract
          IMPORTING ev_message = message RECEIVING rv_ok = ok ).
        IF ok = abap_false. APPEND |Số hợp đồng ủy thác XK: { message }| TO errors. ENDIF.
      ENDIF.
      IF errors IS INITIAL.
        <row>-message_type = 'S'. <row>-message = 'Success'.
      ELSE.
        DATA(full_message) = concat_lines_of( table = errors sep = '; ' ).
        <row>-message_type = 'E'.
        <row>-message = substring( val = full_message len = nmin( val1 = c_max_message val2 = strlen( full_message ) ) ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD update_customer_group.
    DATA(endpoint) = |{ c_service_root }A_SalesOrder('{ is_data-sales_order }')|.
    rv_ok = do_call( EXPORTING iv_endpoint = endpoint iv_method = 'PATCH'
      iv_body = |\{ "CustomerGroup":"{ escape_json( is_data-customer_group ) }" \}|
      IMPORTING ev_message = ev_message ev_code = DATA(code) ev_response = DATA(response) ).
  ENDMETHOD.

  METHOD update_header_text.
    DATA(endpoint) = |{ c_service_root }A_SalesOrderText(SalesOrder='{ is_data-sales_order }',Language='EN',LongTextID='{ iv_text_id }')|.
    rv_ok = do_call( EXPORTING iv_endpoint = endpoint iv_method = 'PATCH'
      iv_body = |\{ "LongText":"{ escape_json( iv_text ) }" \}|
      IMPORTING ev_message = ev_message ev_code = DATA(code) ev_response = DATA(response) ).
    IF rv_ok = abap_false AND code = 404.
      DATA(body) = |\{ "SalesOrder":"{ is_data-sales_order }","Language":"EN","LongTextID":"{ iv_text_id }","LongText":"{ escape_json( iv_text ) }" \}|.
      rv_ok = do_call( EXPORTING iv_endpoint = |{ c_service_root }A_SalesOrderText| iv_method = 'POST' iv_body = body
        IMPORTING ev_message = ev_message ev_code = code ev_response = response ).
    ENDIF.
  ENDMETHOD.

  METHOD do_call.
    ev_response = zcl_call_api=>call_api( iv_body = iv_body iv_endpoint = iv_endpoint iv_apiName = c_api_name iv_method = iv_method ).
    ev_code = zcl_call_api=>code.
    rv_ok = xsdbool( ev_code = 200 OR ev_code = 201 OR ev_code = 204 ).
    IF rv_ok = abap_false. ev_message = error_text( ev_response ). ENDIF.
  ENDMETHOD.

  METHOD error_text.
    IF iv_response IS INITIAL. rv_message = 'API returned no response'. RETURN. ENDIF.
    rv_message = iv_response.
  ENDMETHOD.

  METHOD escape_json.
    rv_text = iv_text.
    REPLACE ALL OCCURRENCES OF `\` IN rv_text WITH `\\`.
    REPLACE ALL OCCURRENCES OF `"` IN rv_text WITH `\"`.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN rv_text WITH `\n`.
  ENDMETHOD.
ENDCLASS.
