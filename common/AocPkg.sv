`include "defines.svh"
package AocPkg;
    localparam ROM_DEPTH = `ROM_DEPTH;
    typedef logic [$clog2(ROM_DEPTH)-1:0] RomAddr_t;
endpackage
