CLASS zcl_mch_so_hdr_parser DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES BEGIN OF ty_row.
    TYPES cid TYPE string.
    TYPES sales_order TYPE string.
    TYPES customer_group TYPE string.
    TYPES lc_number TYPE string.
    TYPES lc_open_date TYPE string.
    TYPES commission_rate TYPE string.
    TYPES export_trust_contract TYPE string.
    TYPES has_customer_group TYPE abap_boolean.
    TYPES has_lc_number TYPE abap_boolean.
    TYPES has_lc_open_date TYPE abap_boolean.
    TYPES has_commission_rate TYPE abap_boolean.
    TYPES has_export_trust_contract TYPE abap_boolean.
    TYPES END OF ty_row.
    TYPES tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.
    CLASS-METHODS parse IMPORTING iv_content TYPE xstring RETURNING VALUE(rt_rows) TYPE tt_row
      RAISING zcx_mch_so_hdr.
  PRIVATE SECTION.
    CONSTANTS c_header_rows TYPE i VALUE 3.
    CONSTANTS c_max_rows TYPE i VALUE 1000.
    CLASS-METHODS parse_date IMPORTING iv_value TYPE string RETURNING VALUE(rv_value) TYPE string.
ENDCLASS.

CLASS zcl_mch_so_hdr_parser IMPLEMENTATION.
  METHOD parse.
    TYPES BEGIN OF ty_input.
    TYPES sales_order TYPE string.
    TYPES customer_group TYPE string.
    TYPES lc_number TYPE string.
    TYPES lc_open_date TYPE string.
    TYPES commission_rate TYPE string.
    TYPES export_trust_contract TYPE string.
    TYPES END OF ty_input.
    DATA inputs TYPE STANDARD TABLE OF ty_input WITH EMPTY KEY.
    TRY.
        DATA(xlsx) = xco_cp_xlsx=>document->for_file_content( iv_file_content = iv_content )->read_access( ).
        DATA(sheet) = xlsx->get_workbook( )->worksheet->at_position( 1 ).
        DATA(pattern) = xco_cp_xlsx_selection=>pattern_builder->simple_from_to( )->get_pattern( ).
        DATA(execute) = sheet->select( pattern )->row_stream( )->operation->write_to( REF #( inputs ) ).
        execute->set_value_transformation( xco_cp_xlsx_read_access=>value_transformation->string_value
          )->if_xco_xlsx_ra_operation~execute( ).
      CATCH cx_root INTO DATA(error).
        RAISE EXCEPTION TYPE zcx_mch_so_hdr EXPORTING text = |Cannot read Excel: { error->get_text( ) }|.
    ENDTRY.
    DO c_header_rows TIMES.
      IF inputs IS NOT INITIAL.
        DELETE inputs INDEX 1.
      ENDIF.
    ENDDO.
    DATA sales_orders TYPE HASHED TABLE OF string WITH UNIQUE KEY table_line.
    DATA sale_order TYPE vbeln.
    LOOP AT inputs INTO DATA(input).
      IF input-sales_order IS INITIAL
         AND input-customer_group IS INITIAL
         AND input-lc_number IS INITIAL
         AND input-lc_open_date IS INITIAL
         AND input-commission_rate IS INITIAL
         AND input-export_trust_contract IS INITIAL.
        CONTINUE.
      ENDIF.
      CLEAR sale_order.
      sale_order = input-sales_order.

      IF input-sales_order IS INITIAL.
        RAISE EXCEPTION TYPE zcx_mch_so_hdr
          EXPORTING
            text = |SO is mandatory at Excel row { sy-tabix + c_header_rows }|.
      ENDIF.
      DATA(sales_order) = |{ sale_order ALPHA = IN }|.
      IF line_exists( sales_orders[ table_line = sales_order ] ).
        RAISE EXCEPTION TYPE zcx_mch_so_hdr
          EXPORTING
            text = |Duplicate SO { input-sales_order } at Excel row { sy-tabix + c_header_rows }|.
      ENDIF.
      INSERT sales_order INTO TABLE sales_orders.
      APPEND VALUE #( cid = |ROW_{ sy-tabix }|
        sales_order =  sales_order
        customer_group = input-customer_group
        lc_number = input-lc_number
        lc_open_date = parse_date( input-lc_open_date )
        commission_rate = input-commission_rate
        export_trust_contract = input-export_trust_contract
        has_customer_group = xsdbool( input-customer_group IS NOT INITIAL )
        has_lc_number = xsdbool( input-lc_number IS NOT INITIAL )
        has_lc_open_date = xsdbool( input-lc_open_date IS NOT INITIAL )
        has_commission_rate = xsdbool( input-commission_rate IS NOT INITIAL )
        has_export_trust_contract = xsdbool( input-export_trust_contract IS NOT INITIAL ) ) TO rt_rows.
    ENDLOOP.
    IF rt_rows IS INITIAL.
      RAISE EXCEPTION TYPE zcx_mch_so_hdr EXPORTING text = 'Excel contains no Sales Order rows'.
    ENDIF.
    IF lines( rt_rows ) > c_max_rows.
      RAISE EXCEPTION TYPE zcx_mch_so_hdr
        EXPORTING
          text = |Excel exceeds the maximum of { c_max_rows } Sales Orders|.
    ENDIF.
  ENDMETHOD.

  METHOD parse_date.
    CONSTANTS c_epoch      TYPE d VALUE '18991230'.  "base cho serial >= 61
    CONSTANTS c_epoch_pre  TYPE d VALUE '18991231'.  "base cho serial <= 59
    CONSTANTS c_max_serial TYPE i VALUE 2958465.     "9999-12-31

    DATA lv_serial TYPE i.
    DATA lv_date   TYPE d.

    CHECK iv_value IS NOT INITIAL.

    DATA(lv_value) = condense( iv_value ).
    rv_value = lv_value.   "mặc định: giữ nguyên những gì user gõ

    " 1) Đã là DD/MM/YYYY -> giữ nguyên
    IF strlen( lv_value ) = 10
       AND lv_value+0(2) CO '0123456789'
       AND lv_value+2(1) = '/'
       AND lv_value+3(2) CO '0123456789'
       AND lv_value+5(1) = '/'
       AND lv_value+6(4) CO '0123456789'.
      RETURN.
    ENDIF.

    " 2) DD.MM.YYYY hoặc DD-MM-YYYY -> chuẩn hoá dấu phân cách
    IF strlen( lv_value ) = 10
       AND lv_value+0(2) CO '0123456789'
       AND ( lv_value+2(1) = '.' OR lv_value+2(1) = '-' )
       AND lv_value+3(2) CO '0123456789'
       AND lv_value+5(1) = lv_value+2(1)
       AND lv_value+6(4) CO '0123456789'.
      rv_value = |{ lv_value+0(2) }/{ lv_value+3(2) }/{ lv_value+6(4) }|.
      RETURN.
    ENDIF.

    " 3) YYYY-MM-DD (ISO)
    IF strlen( lv_value ) = 10
       AND lv_value+0(4) CO '0123456789'
       AND lv_value+4(1) = '-'
       AND lv_value+5(2) CO '0123456789'
       AND lv_value+7(1) = '-'
       AND lv_value+8(2) CO '0123456789'.
      rv_value = |{ lv_value+8(2) }/{ lv_value+5(2) }/{ lv_value+0(4) }|.
      RETURN.
    ENDIF.

    " 4) YYYYMMDD
    IF strlen( lv_value ) = 8 AND lv_value CO '0123456789'.
      rv_value = |{ lv_value+6(2) }/{ lv_value+4(2) }/{ lv_value+0(4) }|.
      RETURN.
    ENDIF.

    " 5) Excel serial number (46023, hoặc 46023.5 nếu ô là datetime)
    DATA(lv_num) = lv_value.
    IF lv_num CS '.'.
      SPLIT lv_num AT '.' INTO lv_num DATA(lv_frac).
    ENDIF.

    IF lv_num CO '0123456789' AND strlen( lv_num ) BETWEEN 1 AND 7.
      lv_serial = lv_num.
      IF lv_serial >= 61 AND lv_serial <= c_max_serial.
        lv_date  = c_epoch + lv_serial.
        rv_value = |{ lv_date+6(2) }/{ lv_date+4(2) }/{ lv_date+0(4) }|.
      ELSEIF lv_serial >= 1 AND lv_serial <= 59.
        lv_date  = c_epoch_pre + lv_serial.
        rv_value = |{ lv_date+6(2) }/{ lv_date+4(2) }/{ lv_date+0(4) }|.
      ENDIF.
      RETURN.
    ENDIF.

    " 6) Text tự do -> giữ nguyên (rv_value đã gán ở đầu method)
  ENDMETHOD.

ENDCLASS.
