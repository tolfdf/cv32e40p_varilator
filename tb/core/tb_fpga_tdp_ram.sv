`timescale 1ns / 1ps

module tb_fpga_tdp_ram;

localparam ADDR_WIDTH = 14;
localparam DATA_WIDTH = 32;

localparam WORDS = 2**ADDR_WIDTH;

logic                      clk_i;
logic                      rst_ni;

logic                      en_a_i;
logic [ADDR_WIDTH-1:0]     addr_a_i;
logic [DATA_WIDTH-1:0]     wdata_a_i;
logic [DATA_WIDTH-1:0]     rdata_a_o;
logic                      we_a_i;
logic [(DATA_WIDTH/8)-1:0] be_a_i;

logic                      en_b_i;
logic [ADDR_WIDTH-1:0]     addr_b_i;
logic [DATA_WIDTH-1:0]     wdata_b_i;
logic [DATA_WIDTH-1:0]     rdata_b_o;
logic                      we_b_i;
logic [(DATA_WIDTH/8)-1:0] be_b_i;

logic [ADDR_WIDTH-1:0] aligned_instr_addr;
logic [ADDR_WIDTH-1:0] aligned_data_addr;
assign aligned_instr_addr = addr_a_i[ADDR_WIDTH-1:2];
assign aligned_data_addr = addr_b_i[ADDR_WIDTH-1:2];

logic [DATA_WIDTH-1:0] expected_values [0:WORDS-1];


initial clk_i = 1;
always #5 clk_i = ~clk_i;

int test_case;
int error_count;

initial
begin
    error_count = 0;
    rst_ni = 0;
    
    en_a_i = 0;
    addr_a_i = 'h180 >> 2;
    wdata_a_i = 0;
    we_a_i = 0;
    be_a_i = 0;
    
    en_b_i = 0;
    addr_b_i = 0;
    wdata_b_i = 0;
    we_b_i = 0;
    be_b_i = 0;

    #20ns rst_ni = 1;
    
    en_a_i = 1;
    #10;
    en_b_i = 1;
    we_b_i = 1;
    
    // Test all modes automatically
    for (test_case = 0; test_case <= 9; test_case++) begin
        $display("Starting test case %0d", test_case);
        we_b_i = 1;

        // Initialize memory with all f
        /*be_b_i = 4'b1111;
        for(int i = 0; i < WORDS; ++i) begin
            addr_b_i = i;
            wdata_b_i = 32'hFFFFFFFF;
            #10;
        end*/
        
        case (test_case)
            0: begin
                be_b_i = 4'b1111;
                for(int i = 0; i < WORDS; ++i) begin
                    addr_b_i = i;
                    wdata_b_i = i*i;
                    #10;       
                end
                we_b_i = 0;  
                be_b_i = 0;     
                #10; 
                for(int i = 0; i < WORDS; ++i) begin
                    addr_b_i = i;
                    #10;
                    if( rdata_b_o !== i*i) begin
                        $fatal(2,"Test case 0: Read error at address %0d: expected %0d, got %0d", i, wdata_b_i, rdata_b_o);
                    end
                end
            end
            
            1: begin
                be_b_i = 4'b1110;
                for(int i = 0; i < WORDS; i++) begin
                    addr_b_i = i;
                    wdata_b_i = $random();
                    expected_values[i] = wdata_b_i;
                    #10;  
                    expected_values[i][7:0] = rdata_b_o[7:0];
                end
                we_b_i = 0;
                be_b_i = 0;     
                #10; 
                for(int i = 0; i < WORDS; i++) begin
                    addr_b_i = i;
                    #10;
                    if( rdata_b_o !==expected_values[i]) begin
                        $fatal(2,"Test case 1: Read error at address %0d: expected %0d, got %0d", i, expected_values[i], rdata_b_o);
                    end
                end
            end

            2: begin
                be_b_i = 4'b1100;
                for(int i = 0; i < WORDS; i++) begin
                    addr_b_i = i;
                    wdata_b_i = $random();
                    expected_values[i] = wdata_b_i;
                    #10;
                    expected_values[i][15:0] = rdata_b_o[15:0];       
                end
                we_b_i = 0;
                be_b_i = 0;     
                #10; 
                for(int i = 0; i < WORDS; i++) begin
                    addr_b_i = i;
                    #10;
                    if( rdata_b_o !==expected_values[i]) begin
                        $fatal(2,"Test case 2: Read error at address %0d: expected %0d, got %0d", i, expected_values[i], rdata_b_o);
                    end
                end
            end
            
            3: begin
                be_b_i = 4'b1000;
                for(int i = 0; i < WORDS; i++) begin
                    addr_b_i = i;
                    wdata_b_i = $random();
                    expected_values[i] = wdata_b_i;
                    #10;  
                    expected_values[i][23:0] = rdata_b_o[23:0];     
                end
                we_b_i = 0;
                be_b_i = 0;     
                #10; 
                for(int i = 0; i < WORDS; i++) begin
                    addr_b_i = i;
                    #10;
                    if( rdata_b_o !==expected_values[i]) begin
                        $fatal(2,"Test case 3: Read error at address %0d: expected %0d, got %0d", i, expected_values[i], rdata_b_o);
                    end
                end
            end

            4: begin
                be_b_i = 4'b0001;
                for(int i = 0; i < WORDS; i++) begin
                    addr_b_i = i;
                    wdata_b_i =$random();
                    expected_values[i] = wdata_b_i;
                    #10;
                    expected_values[i][31:8] = rdata_b_o[31:8];       
                end
                we_b_i = 0;
                be_b_i = 0;     
                #10; 
                for(int i = 0; i < WORDS; i++) begin
                    addr_b_i = i;
                    #10;
                    if( rdata_b_o !==expected_values[i]) begin
                        $fatal(2,"Test case 4: Read error at address %0d: expected %0d, got %0d", i, expected_values[i], rdata_b_o);
                    end
                end
            end

            5: begin
                be_b_i = 4'b0011;
                for(int i = 0; i < WORDS; i++) begin
                    addr_b_i = i;
                    wdata_b_i =$random();
                    expected_values[i] = wdata_b_i;
                    #10;   
                    expected_values[i][31:16] = rdata_b_o[31:16];    
                end
                we_b_i = 0;
                be_b_i = 0;     
                #10; 
                for(int i = 0; i < WORDS; i++) begin
                    addr_b_i = i;
                    #10;
                    if( rdata_b_o !==expected_values[i]) begin
                        $fatal(2,"Test case 5: Read error at address %0d: expected %0d, got %0d", i, expected_values[i], rdata_b_o);
                    end
                end
            end

            6: begin
                be_b_i = 4'b0111;
                for(int i = 0; i < WORDS; i++) begin
                    addr_b_i = i;
                    wdata_b_i =$random();
                    expected_values[i] = wdata_b_i;
                    #10;  
                    expected_values[i][31:24] = rdata_b_o[31:24];     
                end
                we_b_i = 0;
                be_b_i = 0;     
                #10; 
                for(int i = 0; i < WORDS; i++) begin
                    addr_b_i = i;
                    #10;
                    if( rdata_b_o !==expected_values[i]) begin
                        $fatal(2,"Test case 6: Read error at address %0d: expected %0d, got %0d", i, expected_values[i], rdata_b_o);
                    end
                end
            end

            7: begin
                be_b_i = 4'b0110;
                for(int i = 0; i < WORDS; i++) begin
                    addr_b_i = i;
                    wdata_b_i =$random();
                    expected_values[i] = wdata_b_i;
                    #10;  
                    expected_values[i][31:24] = rdata_b_o[31:24]; 
                    expected_values[i][7:0] = rdata_b_o[7:0];    
                end
                we_b_i = 0;
                be_b_i = 0;     
                #10; 
                for(int i = 0; i < WORDS; i++) begin
                    addr_b_i = i;
                    #10;
                    if( rdata_b_o !==expected_values[i]) begin
                        $fatal(2,"Test case 7: Read error at address %0d: expected %0d, got %0d", i, expected_values[i], rdata_b_o);
                    end
                end
            end

            8: begin
                be_b_i = 4'b0010;
                for(int i = 0; i < WORDS; i++) begin
                    addr_b_i = i;
                    wdata_b_i =$random();
                    expected_values[i] = wdata_b_i;
                    #10;  
                    expected_values[i][31:16] = rdata_b_o[31:16];  
                    expected_values[i][7:0] = rdata_b_o[7:0];    
                end
                we_b_i = 0;
                be_b_i = 0;     
                #10; 
                for(int i = 0; i < WORDS; i++) begin
                    addr_b_i = i;
                    #10;
                    if( rdata_b_o !==expected_values[i]) begin
                        $fatal(2,"Test case 8: Read error at address %0d: expected %0d, got %0d", i, expected_values[i], rdata_b_o);
                    end
                end
            end

            9: begin
                be_b_i = 4'b0100;
                for(int i = 0; i < WORDS; i++) begin
                    addr_b_i = i;
                    wdata_b_i =$random();
                    expected_values[i] = wdata_b_i;
                    #10; 
                    expected_values[i][31:24] = rdata_b_o[31:24];  
                    expected_values[i][15:0] = rdata_b_o[15:0];    
                end
                we_b_i = 0;
                be_b_i = 0;     
                #10; 
                for(int i = 0; i < WORDS; i++) begin
                    addr_b_i = i;
                    #10;
                    if( rdata_b_o !==expected_values[i]) begin
                        $fatal(2,"Test case 9: Read error at address %0d: expected %0d, got %0d", i, expected_values[i], rdata_b_o);
                    end
                end
            end
        endcase
        $display("Completed test case %0d", test_case);
    end
       
    we_b_i = 0;
    #10;
    $display("All test cases passed successfully!");
    $finish;
end

fpga_tdp_ram
#(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) DUT (
    .clk_i(clk_i),
    .rst_ni(rst_ni),

    .en_a_i(en_a_i),
    .addr_a_i(aligned_instr_addr),
    .wdata_a_i(wdata_a_i),
    .rdata_a_o(rdata_a_o),
    .we_a_i(we_a_i),
    .be_a_i(be_a_i),

    .en_b_i(en_b_i),
    .addr_b_i(addr_b_i),       //aligned_data_addr      addr_b_i
    .wdata_b_i(wdata_b_i),
    .rdata_b_o(rdata_b_o),
    .we_b_i(we_b_i),
    .be_b_i(be_b_i)
    
    
);

endmodule