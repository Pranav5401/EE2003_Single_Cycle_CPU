module cpu (
    input clk, 
    input reset,
    output [31:0] iaddr,
    input [31:0] idata,
    output [31:0] daddr,
    input [31:0] drdata,
    output [31:0] dwdata,
    output [3:0] dwe,
    output [32*32-1:0] registers
);
    reg [31:0] iaddr;
    reg [31:0] daddr;
    reg [31:0] dwdata;
    reg [3:0]  dwe;

    reg [31:0] register_file[0:31]; //updates register file on clock posedge

    reg [31:0] iaddr_d, daddr_q, dwdata_q; 
    reg [3:0] dwe_q;
    reg branch,branch_q; //flag registers for when branch occurs
    reg we, we_q;

    reg [4:0] reg_file_addr, reg_file_addr_q;
    reg [31:0] register_file_in, register_file_in_q;

    assign registers = {register_file[31], register_file[30], register_file[29], register_file[28], register_file[27], register_file[26], register_file[25], register_file[24], register_file[23], register_file[22], register_file[21], register_file[20], register_file[19], register_file[18], register_file[17], register_file[16], register_file[15], register_file[14], register_file[13], register_file[12], register_file[11], register_file[10], register_file[9], register_file[8], register_file[7], register_file[6], register_file[5], register_file[4], register_file[3], register_file[2], register_file[1], register_file[0]};


    integer i; 
    always @(posedge clk) begin
        if(reset) begin
            iaddr <= 0;
            for(i=0; i<32; i=i+1) begin
                register_file[i] <= 0;
            end
            daddr_q <= 0;
            dwdata_q <= 0;
            dwe_q <= 0;
            branch_q <= 0;
            we_q <= 0;
            reg_file_addr_q <= 0;
            register_file_in_q <= 0;
        end else begin 
            if(branch == 1)
                iaddr <= iaddr_d;
            else
                iaddr <= iaddr_d + 4;
                
            daddr_q <= daddr;
            if(reg_file_addr == 0)
                register_file[reg_file_addr] <= 0;
            else if(we) begin 
                register_file[reg_file_addr] <= register_file_in;
            end
            
            dwdata_q <= dwdata;
            dwe_q <= dwe;
            we_q <= we;
            reg_file_addr_q <= reg_file_addr;
            register_file_in_q <= register_file_in;
        end
    end

    always @(*) begin
            branch = branch_q;
            iaddr_d = iaddr;
            daddr = daddr_q;
            we = we_q;
            dwdata = dwdata_q;
            dwe = dwe_q;
            reg_file_addr = reg_file_addr_q;
            register_file_in = register_file_in_q;
        
        if(idata[1:0] == 'b11) begin
        	
        	//Load	
			if(idata[6:2] == 'b00000) begin
				
				//LB
				if({idata[14:12]} == 'b000) begin
				    daddr = register_file[idata[19:15]] + {{20{idata[31]}},idata[31:20]};
				    reg_file_addr = idata[11:7]; 
				    register_file_in ={{24{drdata[7]}},drdata[7:0]};
				    dwe = 0;
				    we = 1;
				end
				
				//LH
				if({idata[14:12]} == 'b001) begin
				    daddr = register_file[idata[19:15]] + {{20{idata[31]}},idata[31:20]};
				    reg_file_addr = idata[11:7]; 
				    register_file_in ={{16{drdata[15]}},drdata[15:0]};
				    dwe = 0;
				    we = 1;
				end
				
				//LW
				if({idata[14:12]} == 'b010) begin
				    daddr = register_file[idata[19:15]] + {{20{idata[31]}},idata[31:20]};
				    reg_file_addr = idata[11:7]; 
				    register_file_in =drdata[31:0];
				    dwe = 0;
				    we = 1;
				end
				
				//LBU
				if({idata[14:12]} == 'b100) begin
				    daddr = register_file[idata[19:15]] + {{20{idata[31]}},idata[31:20]};
				    reg_file_addr = idata[11:7]; 
				    register_file_in ={{24{1'b0}},drdata[7:0]};
				    dwe = 0;
				    we = 1;
				end
				
				//LHU
				if({idata[14:12]} == 'b101) begin
				    daddr = register_file[idata[19:15]] + {{20{idata[31]}},idata[31:20]};
				    reg_file_addr = idata[11:7]; 
				    register_file_in ={{16{1'b0}},drdata[15:0]};
				    dwe = 0;
				    we = 1;
				end
			end	
			
			//Store
			if(idata[6:2] == 'b01000) begin	
				//SB
				if({idata[14:12]} == 'b000) begin
				    daddr = register_file[idata[19:15]] + {{20{idata[31]}},idata[31:25],idata[11:7]};
				    
				    if(daddr % 4 == 0) begin dwe[0] = 1'b1; dwdata[7:0] = (daddr==0)?0:register_file[idata[24:20]][7:0]; end
				    if(daddr % 4 == 1) begin dwe[1] = 1'b1; dwdata[15:8] = (daddr==0)?0:register_file[idata[24:20]][7:0]; end
				    if(daddr % 4 == 2) begin dwe[2] = 1'b1; dwdata[23:16] = (daddr==0)?0:register_file[idata[24:20]][7:0]; end
				    if(daddr % 4 == 3) begin dwe[3] = 1'b1; dwdata[31:23] = (daddr==0)?0:register_file[idata[24:20]][7:0]; end
				    we = 0;
				end
				
				//SH
				if({idata[14:12]} == 'b001) begin
				    we = 0;
				    daddr = register_file[idata[19:15]] + {{20{idata[31]}},idata[31:25],idata[11:7]};
				    if(daddr % 4 == 0) begin dwe[1:0] = 2'b11; dwdata[15:0] = (daddr==0)?0:register_file[idata[24:20]][15:0]; end
				    if(daddr % 4 == 2) begin dwe[3:2] = 2'b11; dwdata[31:16] = (daddr==0)?0:register_file[idata[24:20]][15:0]; end
				end
				
				//SW
				if({idata[14:12]} == 'b010) begin
				    daddr = register_file[idata[19:15]] + {{20{idata[31]}},idata[31:25],idata[11:7]};
				    we = 0;
				    dwe = 4'b1111;
				    dwdata = (daddr==0)?0:register_file[idata[24:20]];
				end
			end
			
        	
        	//LUI
		    if(idata[6:2] == 'b01101) begin 
		        reg_file_addr = idata[11:7]; 
		        register_file_in ={idata[31:12],{12{1'b0}}};
		        dwe = 0;
		        we = 1;
		    end
		    
		    //AUIPC
		    if(idata[6:2] == 'b00101) begin
		        reg_file_addr = idata[11:7]; 
		        register_file_in =iaddr_d + {idata[31:12],{12{1'b0}}};
		        dwe = 0;
		        we = 1;
		    end
		    
		    //ALUi
		    if(idata[6:2] == 'b00100) begin
		    
		    	//addi
				if({idata[14:12]} == 'b000) begin
				    reg_file_addr = idata[11:7]; 
				    register_file_in =register_file[idata[19:15]] + {{20{idata[31]}},idata[31:20]};
				    dwe = 0;
				    we = 1;
				end
				
				//slti
				if({idata[14:12]} == 'b010) begin 
				    reg_file_addr = idata[11:7]; 
				    register_file_in =$signed(register_file[idata[19:15]])<$signed({{20{idata[31]}},idata[31:20]})?{{31{1'b0}},1'b1}:{32{1'b0}};
				    dwe = 0;
				    we = 1;
				end
				
				//sltiu
				if({idata[14:12]} == 'b011) begin 
				    reg_file_addr = idata[11:7]; 
				    register_file_in =register_file[idata[19:15]]<{{20{1'b0}},idata[31:20]}?{{31{1'b0}},1'b1}:{32{1'b0}};
				    dwe = 0;
				    we = 1;
				end
				
				//xori
				if({idata[14:12]} == 'b100) begin
				    reg_file_addr = idata[11:7]; 
				    register_file_in =register_file[idata[19:15]] ^ {{20{idata[31]}},idata[31:20]};
				    dwe = 0;
				    we = 1;
				end
				
				//ori
				if({idata[14:12]} == 'b110) begin
				    reg_file_addr = idata[11:7]; register_file_in =register_file[idata[19:15]] | {{20{idata[31]}},idata[31:20]};
				    dwe = 0;
				    we = 1;
				end
				
				//andi
				if({idata[14:12]} == 'b111) begin
				    reg_file_addr = idata[11:7]; register_file_in =register_file[idata[19:15]] & {{20{idata[31]}},idata[31:20]};
				    dwe = 0;
				    we = 1;
				end
				
				//slli
				if({idata[31:25],idata[14:12]} == 'b0000000001) begin
				    reg_file_addr = idata[11:7]; 
				    register_file_in =register_file[idata[19:15]] << idata[24:20];
				    dwe = 0;
				    we = 1;
				end
				
				//srli
				if({idata[31:25],idata[14:12]} == 'b0000000101) begin
				    reg_file_addr = idata[11:7]; 
				    register_file_in =register_file[idata[19:15]] >> idata[24:20];
				    dwe = 0;
				    we = 1;
				end
				
				//srai
				if({idata[31:25],idata[14:12]} == 'b0100000101) begin
				    reg_file_addr = idata[11:7]; 
				    register_file_in =register_file[idata[19:15]] >>> idata[24:20];
				    dwe = 0;
				    we = 1;
				end
			end	
			
			//ALU
			if(idata[6:2] == 'b01100) begin	
				
				//add
				if({idata[31:25],idata[14:12]} == 'b0000000000) begin
				    reg_file_addr = idata[11:7]; 
				    register_file_in = register_file[idata[19:15]] + register_file[idata[24:20]];
				    dwe = 0;
				    we = 1;
				end
				
				//sub
				if({idata[31:25],idata[14:12]} == 'b0100000000) begin
				    reg_file_addr = idata[11:7]; 
				    register_file_in = register_file[idata[19:15]] - register_file[idata[24:20]];
				    dwe = 0;
				    we = 1;
				end
				
				//sll
				if({idata[31:25],idata[14:12]} == 'b0000000001) begin
				    reg_file_addr = idata[11:7]; 
				    register_file_in = register_file[idata[19:15]] << register_file[idata[24:20]][4:0];
				    dwe = 0;
				    we = 1;
				end
				
				//slt
				if({idata[31:25],idata[14:12]} == 'b0000000010) begin
				    reg_file_addr = idata[11:7]; 
				    register_file_in = $signed(register_file[idata[19:15]])<$signed(register_file[idata[24:20]])?{{31{1'b0}},1'b1}:{32{1'b0}};
				    dwe = 0;
				    we = 1;
				end
				
				//sltu
				if({idata[31:25],idata[14:12]} == 'b0000000011) begin
				    reg_file_addr = idata[11:7]; 
				    register_file_in = register_file[idata[19:15]]<register_file[idata[24:20]]?{{31{1'b0}},1'b1}:{32{1'b0}};
				    dwe = 0;
				    we = 1;
				end
				
				//xor
				if({idata[31:25],idata[14:12]} == 'b0000000100) begin
				    reg_file_addr = idata[11:7]; 
				    register_file_in = register_file[idata[19:15]] ^ register_file[idata[24:20]];
				    dwe = 0;
				    we = 1;
				end
				
				//srl
				if({idata[31:25],idata[14:12]} == 'b0000000101) begin
				    reg_file_addr = idata[11:7]; 
				    register_file_in = register_file[idata[19:15]] >> register_file[idata[24:20]];
				    dwe = 0;
				    we = 1;
				end
				
				//sra
				if({idata[31:25],idata[14:12]} == 'b0100000101) begin
				    reg_file_addr = idata[11:7];
				    register_file_in = register_file[idata[19:15]] >>> register_file[idata[24:20]];
				    dwe = 0;
				    we = 1;
				end
				
				//or
				if({idata[31:25],idata[14:12]} == 'b0000000110) begin
				    reg_file_addr = idata[11:7]; 
				    register_file_in = register_file[idata[19:15]] | register_file[idata[24:20]];
				    dwe = 0;
				    we = 1;
				end
				
				//and
				if({idata[31:25],idata[14:12]} == 'b0000000111) begin
				    reg_file_addr = idata[11:7];
				    register_file_in = register_file[idata[19:15]] & register_file[idata[24:20]];
				    dwe = 0;
				    we = 1;
				end
			end	
				
			
				
			
			//JAL	
		    if(idata[6:0] == 7'b1101111) begin
		        reg_file_addr = idata[11:7];
		        register_file_in =(reg_file_addr==0)?0:iaddr_d + 4;
		        iaddr_d = iaddr + {{12{idata[31]}},idata[19:12],idata[20],idata[30:21],1'b0};
		        branch = 1;
		        dwe = 0;
		        we = 1;
		    end
		    
		    //JALR
		    if({idata[14:12],idata[6:0]} == 10'b0001100111) begin
		        reg_file_addr = idata[11:7]; 
		        register_file_in =(reg_file_addr==0)?0:iaddr_d + 4;
		        iaddr_d = (register_file[idata[19:15]] + {{20{idata[31]}},idata[31:20]})&~1; 
		        branch = 1;
		        dwe = 0;
		        we = 1;
		    end
		    
		    //BEQ 
		    if({idata[14:12],idata[6:0]} == 10'b0001100011) begin
		        if(register_file[idata[24:20]] == register_file[idata[19:15]]) begin 
		            iaddr_d = iaddr_d + {{20{idata[31]}},idata[7],idata[30:25],idata[11:8],1'b0};
		            branch = 1;
		        end
		        dwe = 0;
		        we = 0;
		    end
		    
		    //BNE
		    if({idata[14:12],idata[6:0]} == 10'b0011100011) begin
		        if((register_file[idata[24:20]] > register_file[idata[19:15]]) || (register_file[idata[24:20]] < register_file[idata[19:15]])) begin 
		            iaddr_d = iaddr_d + {{20{idata[31]}},idata[7],idata[30:25],idata[11:8],1'b0};
		            branch = 1;
		        end 
		        dwe = 0;
		        we = 0;
		    end
		    
		    //BLT
		    if({idata[14:12],idata[6:0]} == 10'b1001100011) begin
		        if($signed(register_file[idata[19:15]]) < $signed(register_file[idata[24:20]])) begin
		            iaddr_d = iaddr_d + {{20{idata[31]}},idata[7],idata[30:25],idata[11:8],1'b0};
		            branch = 1;
		        end 
		        dwe = 0;
		        we = 0;
		    end
		    
		    //BGE
		    if({idata[14:12],idata[6:0]} == 10'b1011100011) begin
		        if($signed(register_file[idata[19:15]]) >= $signed(register_file[idata[24:20]])) begin 
		            iaddr_d = iaddr_d + {{20{idata[31]}},idata[7],idata[30:25],idata[11:8],1'b0};
		            branch = 1;
		        end
		        dwe = 0;
		        we = 0;
		    end
		    
		    //BLTU
		    if({idata[14:12],idata[6:0]} == 10'b1101100011) begin
		        if(register_file[idata[19:15]] < register_file[idata[24:20]]) begin 
		            iaddr_d = iaddr_d + {{20{idata[31]}},idata[7],idata[30:25],idata[11:8],1'b0};
		            branch = 1;
		        end 
		        dwe = 0;
		        we = 0;
		    end
		    
		    //BGEU
		    if({idata[14:12],idata[6:0]} == 10'b1111100011) begin
		        if(register_file[idata[19:15]] >= register_file[idata[24:20]]) begin 
		            iaddr_d = iaddr_d + {{20{idata[31]}},idata[7],idata[30:25],idata[11:8],1'b0};
		            branch = 1;
		        end 
		        dwe = 0;
		        we = 0;
		    end
		end	    
    end 

endmodule
