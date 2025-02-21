`timescale 1ns/1ps

module fulladder_bit (S, Co,A,B,Ci);
    input A,B,Ci;
    output reg S,Co;
    always @(*) begin
        case ({Ci,A,B})
            'b000: {Co,S}='b00;
            'b001: {Co,S}='b01;
            'b010: {Co,S}='b01;
            'b011: {Co,S}='b10;
            'b100: {Co,S}='b01;
            'b101: {Co,S}='b10;
            'b110: {Co,S}='b10;
            'b111: {Co,S}='b11;
        endcase    
    end
    
endmodule

module ADD (F,CF,A,B,EN);
    input EN;
    parameter SIZE = 32;
    output reg [SIZE-1:0] F;
    input wire [SIZE-1:0] A,B;
    output reg CF;
    wire [SIZE-1:0] c;
    wire [SIZE-1:0] Fw;
    wire CFw;
    genvar  i;

    always @(*) begin
        if(EN==1) begin 
            {CF,F} <= A+B;
        end
        else begin F<=32'bz;
            CF <= 1'bz;
        end
    end

    generate
        for (i=0;i<=31 ;i=i+1 ) begin
            case (i)
                0: fulladder_bit fa0(Fw[0], c[0],A[0],B[0],0);
                SIZE-1 :fulladder_bit fah(Fw[SIZE-1], CFw ,A[SIZE-1],B[SIZE-1],c[SIZE-2]);
                default: fulladder_bit fa(Fw[i],c[i],A[i],B[i],c[i-1]);
            endcase
        end
    endgenerate
    
endmodule

