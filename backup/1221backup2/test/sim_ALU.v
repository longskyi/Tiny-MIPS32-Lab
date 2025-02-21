`timescale 1ns/1ps



module sim_alu ();
    reg [31:0] A,B;
    reg [2:0] OP;
    wire [31:0] F_1;
    wire [31:0] F_2;
    wire ZF_2,CF_2,OF_2,SF_2,PF_2;
    wire ZF_1,CF_1,OF_1,SF_1,PF_1;
    initial begin
        A=0; B=0;
        OP=0; //and
        begin   #2 A='hacd4_38f4; B='h1930_a333; //ans='h0810_2030
                #2 A='h0022_2314; B='ha934_3489; //ans='h0020_2000
        end
        #2
        OP=1; //or
        begin   #2 A='hacd4_38f4; B='hd930_a333; //ans='hFDF4_BBF7
        end
        #2
        OP=2; //xor
        begin   #2 A='hacd4_38f4; B='h1930_a333; //ans='hb5e4_9bc7
        end
        #2
        OP=3; //nor
        begin   #2 A='hacd4_38f4; B='h1930_a333; //ans= 420b 4408
        end
        #2
        OP=4; //add
        begin   #2 A='hacd4_38f4; B='h1930_a333; 
                #2 A='hf920_acdd; B='h32aa_bbcc;
                #2 A='h7999_aaaa; B='h7999_0000;
        end
        #2
        OP=5; //sub
        begin   #2 A='h0cd4_38f4; B='h1930_a333;
                #2 A='haaaa_bbbb; B='h2322_aaaa;
        end
        #2
        OP=6; //cmp
        begin   #2 A='hacd4_38f4; B='h1930_a333;
                #2 A='h0000_1111; B='ha000_bbbb;
        end
        #2
        OP=7; //sal
        begin   #2 B='hacd4_38f4; A='h0000_0009; //1 a871_e800
                #2 A='h00aa_aaaa; B='h0000_00aa; // 0000 OF;
        end
    end
    ALU   alu1(.F(F_2),.A(A),.B(B),.OP({0,OP}),.ZF(ZF_2) , .CF(CF_2) , .OF(OF_2) ,.SF(SF_2), .PF(PF_2));
endmodule