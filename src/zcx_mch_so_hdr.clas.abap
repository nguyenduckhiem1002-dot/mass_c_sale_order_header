CLASS zcx_mch_so_hdr DEFINITION PUBLIC INHERITING FROM cx_no_check FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    DATA text TYPE string READ-ONLY.
    METHODS constructor IMPORTING text TYPE string.
ENDCLASS.

CLASS zcx_mch_so_hdr IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    me->text = text.
  ENDMETHOD.
ENDCLASS.
