`timescale 1ns/1ps

module sim_cpu ();
    


    reg CLK,RST;
    wire [5:0] ROM_A1,ROM_A2;
    wire [31:0] ROM_RD1,ROM_RD2;


    initial begin
        CLK=0;
        RST=1;
        fork
            repeat(2000) begin
                #10 CLK=~CLK;
            end
            begin
                #52 RST=0;
            end
        join
    end



    MIPS32_CPU cpu(
        CLK,RST,ROM_A1,ROM_A2,ROM_RD1,ROM_RD2
    );

    IMem ROM(
        ROM_A1,ROM_A2,ROM_RD1,ROM_RD2
    );

endmodule