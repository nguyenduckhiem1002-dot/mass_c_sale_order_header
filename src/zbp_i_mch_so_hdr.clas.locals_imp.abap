CLASS lhc_header DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS validateRow FOR VALIDATE ON SAVE
      IMPORTING keys FOR Header~validateRow.
    METHODS process FOR MODIFY
      IMPORTING keys FOR ACTION Header~process RESULT result.
ENDCLASS.

CLASS lhc_header IMPLEMENTATION.
  METHOD validateRow.
    READ ENTITIES OF zi_mch_so_hdr IN LOCAL MODE
      ENTITY Header FIELDS ( SalesOrder ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      IF row-SalesOrder IS INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-header.
        APPEND VALUE #( %tky = row-%tky
          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                         text = 'SO is mandatory' )
          %element-SalesOrder = if_abap_behv=>mk-on ) TO reported-header.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD process.
    MODIFY ENTITIES OF zi_mch_so_hdr IN LOCAL MODE
      ENTITY Header UPDATE FIELDS ( MessageType Message )
      WITH VALUE #( FOR key IN keys
        ( %tky = key-%tky MessageType = 'J' Message = 'Queued for processing'
          %control-MessageType = if_abap_behv=>mk-on %control-Message = if_abap_behv=>mk-on ) )
      FAILED failed REPORTED reported.
    READ ENTITIES OF zi_mch_so_hdr IN LOCAL MODE
      ENTITY Header ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(rows).
    result = VALUE #( FOR row IN rows ( %tky = row-%tky %param = row ) ).
  ENDMETHOD.
ENDCLASS.
