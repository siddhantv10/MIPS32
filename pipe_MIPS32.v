module pipe_MIPS32 (clk1, clk2);

input clk1, clk2;           // two phase clock

reg [31:0]  PC, IF_ID_IR, IF_ID_NPC;

reg [31:0]  ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm;

reg [2:0]   ID_EX_type, EX_MEM_type, MEM_WB_type;

reg [31:0]  EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B;

reg         EX_MEM_cond;

reg [31:0]  MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;

reg [31:0]  Reg [0:31];              //reg bank
reg [31:0]  Mem [0:1023];            //1024 x 32 memory

parameter   ADD = 6'b000000,  SUB = 6'b000001, AND = 6'b000010, OR = 6'b000011,
            SLT = 6'b000100,  MUL = 6'b000101, HLT = 6'b111111, LW = 6'b001000,
            SW  = 6'b001001,  ADDI= 6'b001010, SUBI= 6'b001011, SLTI=6'b001100,
            BNEQZ = 6'b001101, BEQZ= 6'b001110;

parameter   RR_ALU = 3'b000,  RM_ALU = 3'b001,    LOAD = 3'b010, STORE = 3'b011,
            BRANCH = 3'b100,  HALT = 3'b101;

reg HALTED;         //Set after halt instruction is completed
reg TAKEN_BRANCH;   //Required to disable instructions after branch



//Instruction Fetch = IF STAGE

always @ (posedge clk1)
    if(HALTED == 0)
    begin
                                //Execution of Branching

        if( ( (EX_MEM_IR[31:26] == BEQZ) && (EX_MEM_cond == 1) || (EX_MEM_IR == BNEQZ) && (EX_MEM_cond == 0) ) )//condition for 
                                                                                                                //branching

        begin
            IF_ID_IR        <= #2   Mem[EX_MEM_ALUOut];
            TAKEN_BRANCH    <= #2   1'b1;
            IF_ID_NPC       <= #2   EX_MEM_ALUOut + 1;
            PC              <= #2   EX_MEM_ALUOut + 1;
        end

        else    //Fetch
        
        begin
            IF_ID_IR        <= #2 Mem[PC];
            IF_ID_NPC       <= #2 PC + 1;
            PC              <= #2 PC + 1;        
        end
    end


//Instruction Decode = ID STAGE

always @ (posedge clk2)
    if(HALTED == 0)
    begin
        
        if (IF_ID_IR[25:21] == 5'b00000)        ID_EX_A <= 0;   //checking if source register is zero
        
        else    ID_EX_A     <= #2 Reg[IF_ID_IR[25:21]];         //otherwise assign it the values from the reg bank


        if (IF_ID_IR[20:16] == 5'b00000)        ID_EX_B <= 0;   //for target register

        else    ID_EX_B     <= #2 Reg[IF_ID_IR[20:16]];     

        ID_EX_NPC   <= #2 IF_ID_NPC;        //passing elements from stage IF to ID
        ID_EX_IR    <= #2 IF_ID_IR;
        ID_EX_Imm   <= #2 {{ 16{IF_ID_IR[15]}}, {IF_ID_IR[15:0]}};      //sign extension into 32 bits

        //Decoding the opcode TYPE and setting the TYPE REGISTER

        case(IF_ID_IR[31:26])
        ADD, SUB, AND, OR, SLT, MUL:     ID_EX_type <= #2 RR_ALU;
        ADDI, SUBI, SLTI:                ID_EX_type <= #2 RM_ALU;
        LW:                              ID_EX_type <= #2 LOAD;
        SW:                              ID_EX_type <= #2 STORE;
        BNEQZ, BEQZ:                     ID_EX_type <= #2 BRANCH;
        HLT:                             ID_EX_type <= #2 HALT;
        default:                         ID_EX_type <= #2 HALT; //for invalid opcode
                                                                
        endcase
    end


//Execute = EX STAGE

always @ (posedge clk1)
    if (HALTED == 0)
    begin
        
        EX_MEM_type  <= #2 ID_EX_type;       //passing elements across pipeline stage
        EX_MEM_IR    <= #2 ID_EX_IR;
        TAKEN_BRANCH <= #2 0;               //Reset the taken branch register

        case (ID_EX_type)
            RR_ALU:     //Register Register TYPE
            begin
                case (ID_EX_IR[31:26])  //decoding the opcode to perform the operation as ALU
                ADD:    EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_B;
                SUB:    EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_B;
                AND:    EX_MEM_ALUOut <= #2 ID_EX_A & ID_EX_B;
                OR:     EX_MEM_ALUOut <= #2 ID_EX_A | ID_EX_B;
                SLT:    EX_MEM_ALUOut <= #2 ID_EX_A < ID_EX_B;
                MUL:    EX_MEM_ALUOut <= #2 ID_EX_A * ID_EX_B;
                default: EX_MEM_ALUOut<= #2 32'hxxxxxxxx;
                endcase
            end

            RM_ALU:     //Regsiter Memory OFFSET Type
            begin
                case (ID_EX_IR[31:26])   
                ADDI:    EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm;
                SUBI:    EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_Imm;
                SLTI:    EX_MEM_ALUOut <= #2 ID_EX_A < ID_EX_Imm;
                default: EX_MEM_ALUOut<= #2 32'hxxxxxxxx;
                endcase   
            end
            
            LOAD, STORE: //LOAD STORE
            begin
                EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm; //Calculating the address of the memory
                EX_MEM_B      <= #2 ID_EX_B;             //forwarded B as it will be needed for store operation
            end

            BRANCH:
            begin
                EX_MEM_ALUOut <= #2 ID_EX_NPC + ID_EX_Imm; //Calculate the target address of the branch
                EX_MEM_cond   <= #2 (ID_EX_A == 0);         //calculating cond, which is used in IF Stage         
            end
        endcase

    end

//Memory R/W Operations= MEM STAGE

always @ (posedge clk2)
    if (HALTED == 0)
    begin
        MEM_WB_type <= #2 EX_MEM_type; //type and IR forwarded
        MEM_WB_IR   <= #2 EX_MEM_IR;

        case (EX_MEM_type)
        RR_ALU, RM_ALU:     MEM_WB_ALUOut   <= #2 EX_MEM_ALUOut; //for RR and RM type operations, Memory isnt needed

        LOAD :              MEM_WB_LMD      <= #2 Mem[EX_MEM_ALUOut];   //LOADING THE GIVEN MEMORY ADDRESS

        STORE:  if (TAKEN_BRANCH == 0)          // CHECK IF WRITE IS ENABLED. If TAKEN_BRANCH = 1, write is disabled
                            Mem[EX_MEM_ALUOut] <= #2 EX_MEM_B;
        endcase 
    end 

//Write Back in Registers = WB STAGE

always @ (posedge clk1)
    begin
        if (TAKEN_BRANCH == 0)      //if 1 , Disable write
        case (MEM_WB_type)
        RR_ALU:     Reg[MEM_WB_IR[15:11]]   <= #2 MEM_WB_ALUOut;    //r destination

        RM_ALU:     Reg[MEM_WB_IR[20:16]]   <= #2 MEM_WB_ALUOut;    //r target

        LOAD:       Reg[MEM_WB_IR[20:16]]   <= #2 MEM_WB_LMD;       //r target

        HALT:       HALTED <= #2 1'b1;
        endcase 
    end

endmodule
