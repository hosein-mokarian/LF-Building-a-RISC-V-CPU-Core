\m4_TLV_version 1d: tl-x.org
\SV
   // This code can be found in: https://github.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/risc-v_shell.tlv
   
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/warp-v_includes/1d1023ccf8e7b0a8cf8e8fc4f0a823ebb61008e3/risc-v_defs.tlv'])
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/main/lib/risc-v_shell_lib.tlv'])



   //---------------------------------------------------------------------------------
   // /====================\
   // | Sum 1 to 9 Program |
   // \====================/
   //
   // Program to test RV32I
   // Add 1,2,3,...,9 (in that order).
   //
   // Regs:
   //  x12 (a2): 10
   //  x13 (a3): 1..10
   //  x14 (a4): Sum
   // 
   m4_asm(ADDI, x14, x0, 0)             // Initialize sum register a4 with 0
   m4_asm(ADDI, x12, x0, 1010)          // Store count of 10 in register a2.
   m4_asm(ADDI, x13, x0, 1)             // Initialize loop count register a3 with 0
   // Loop:
   m4_asm(ADD, x14, x13, x14)           // Incremental summation
   m4_asm(ADDI, x13, x13, 1)            // Increment loop count by 1
   m4_asm(BLT, x13, x12, 1111111111000) // If a3 is less than a2, branch to label named <loop>
   // Test result value in x14, and set x31 to reflect pass/fail.
   m4_asm(ADDI, x30, x14, 111111010100) // Subtract expected value of 44 to set x30 to 1 if and only iff the result is 45 (1 + 2 + ... + 9).
   m4_asm(BGE, x0, x0, 0) // Done. Jump to itself (infinite loop). (Up to 20-bit signed immediate plus implicit 0 bit (unlike JALR) provides byte address; last immediate bit should also be 0)
   m4_asm_end()
   m4_define(['M4_MAX_CYC'], 50)
   //---------------------------------------------------------------------------------



\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
   /* verilator lint_on WIDTH */
\TLV
   
   $reset = *reset;
   
   
   // YOUR CODE HERE
   // ...
   $is_jalr = 1'b0;
   $pc[31:0] = >>1$next_pc[31:0];
   $next_pc[31:0] = ($reset == 1'b1) ? 32'b0 :
                    $taken_br ? $br_tgt_pc[31:0] :
                    $is_jalr ? $jalr_tgt_pc[31:0] :
                    ($pc[31:0] + 4);
   
   `READONLY_MEM($pc, $$read_data[31:0])
   
   $instr[31:0] = $read_data;
   $is_u_instr = $instr[6:2] ==? 5'b0x101;
   // $is_i_instr = $instr[6:2] ==? 5'b0x101;
   // $is_r_instr = $instr[6:2] ==? 5'b0x101;
   $is_s_instr = $instr[6:2] ==? 5'b0100x;
   $is_b_instr = $instr[6:2] ==? 5'b11000;
   $is_j_instr = $instr[6:2] ==? 5'b11011;
   
   $is_r_instr = $instr[6:2] == 5'b01011 ||
                 $instr[6:2] == 5'b01100 ||
                 $instr[6:2] == 5'b01110 ||
                 $instr[6:2] == 5'b10100;
   $is_i_instr = $instr[6:2] == 5'b00000 ||
                 $instr[6:2] == 5'b00001 ||
                 $instr[6:2] == 5'b00100 ||
                 $instr[6:2] == 5'b00110 ||
                 $instr[6:2] == 5'b11001;
   
   $is_load = $instr[6:2] == 5'b11000;
   
   $rs2[4:0] = $instr[24:20];
   $rs2_valid = $is_r_instr ||
                $is_s_instr ||
                $is_b_instr;
   
   $imm_valid = $is_s_instr ||
                $is_b_instr ||
                $is_j_instr ||
                $is_u_instr ||
                $is_i_instr;
   
   `BOGUS_USE($rd $rd_valid $rs1 $rs1_valid ...)
   
   $imm[31:0] = $is_i_instr ? {  {21{$instr[31]}},  $instr[30:20]  } :
                $is_s_instr ? {  {21{$instr[31]}},  $instr[30:25], $instr[11:8] , $instr[7]  } :
                $is_b_instr ? {  {20{$instr[31]}},  $instr[7], $instr[30:25], $instr[11:8] , 1'b0  } :
                $is_u_instr ? {  $instr[31], $instr[30:20], $instr[19:12], 12'b0  } :
                $is_j_instr ? {  {12{$instr[31]}},  $instr[19:12], $instr[20], $instr[30:25], $instr[24:21], 1'b0} :
                32'b0;  // Default
   
   $opcode[6:0] = $instr[6:0];
   $funct3[2:0] = $instr[14:12];
   $funct7[6:0] = $is_r_instr ? $instr[31:25] :
                  7'b0;
   
   $dec_bits[10:0] = {$funct7[5],$funct3,$opcode};
   
   $is_beq = $dec_bits ==? 11'bx_000_1100011;
   $is_bne = $dec_bits ==? 11'bx_001_1100011;
   $is_blt = $dec_bits ==? 11'bx_100_1100011;
   $is_bge = $dec_bits ==? 11'bx_101_1100011;
   $is_bltu = $dec_bits ==? 11'bx_110_1100011;
   $is_bgeu = $dec_bits ==? 11'bx_111_1100011;
   $is_addi = $dec_bits ==? 11'bx_000_0010011;
   
   $is_add = $dec_bits ==? 11'bx_000_0110011;
   
   $is_LB = $dec_bits ==? 11'bx_000_0000011;
   $is_LH = $dec_bits ==? 11'bx_001_0000011;
   $is_LW = $dec_bits ==? 11'bx_010_0000011;
   $is_LBU = $dec_bits ==? 11'bx_100_0000011;
   $is_LHU = $dec_bits ==? 11'bx_101_0000011;
   $is_SB = $dec_bits ==? 11'bx_000_0100011;
   $is_SH = $dec_bits ==? 11'bx_001_0100011;
   $is_SW = $dec_bits ==? 11'bx_010_0100011;
   
   $wr_index[4:0] = $instr[11:7];
   $rd1_index[4:0] = $instr[19:15];
   $rd2_index[4:0] = $instr[24:20];
   
   $rd1_en = $is_i_instr ? 1'b1 :
             $is_r_instr ? 1'b1 :
             $is_b_instr ? 1'b1 :
             1'b0;
   $rd2_en = $is_r_instr ? 1'b1 :
             $is_b_instr ? 1'b1 :
             1'b0;
   $wr_en = $wr_index != 5'b0 ? 1'b1 :
            $is_i_instr ? 1'b1 :
            $is_r_instr ? 1'b1 :
            1'b0;
   
   $src1_value[31:0] = $rd1_data[31:0];
   $src2_value[31:0] = $rd2_data[31:0];
   
   $is_jal = 1'b0;
   $taken_br = $is_b_instr && $is_beq ? $src1_value == $src2_value :
               $is_b_instr && $is_bne ? $src1_value != $src2_value :
               $is_b_instr && $is_blt ? ($src1_value < $src2_value) ^ ($src1_value[31] != $src2_value[31]) :
               $is_b_instr && $is_bge ? ($src1_value >= $src2_value) ^ ($src1_value[31] != $src2_value[31]) :
               $is_b_instr && $is_bltu ? ($src1_value < $src2_value) :
               $is_b_instr && $is_bgeu ? ($src1_value >= $src2_value) :
               $is_jal ? 1'b1 :
               1'b0;
   $br_tgt_pc[31:0] = $taken_br ? $pc[31:0] + $imm : $pc[31:0];
   
   $jalr_tgt_pc[31:0] = $src1_value + $imm;
   
   $sltu_rslt[31:0] = {31'b0, $src1_value < $src2_value};
   $sltiu_rslt[31:0] = {31'b0, $src1_value < $imm};
   
   $sext_src1[63:0] = { {32{$src1_value[31]}}, $src1_value };
   
   $sra_rslt[63:0] = $sext_src1 >> $src2_value[4:0];
   $srai_rslt[63:0] = $sext_src1 >> $imm[4:0];
   
   $result[31:0] = $is_addi || $is_load || $is_s_instr ? $src1_value + $imm :
                   $is_add ? $src1_value +  $src2_value:
                   $is_andi ? $src1_value & $imm:
                   $is_orii ? $src1_value | $imm:
                   $is_xor ? $src1_value ^ $imm:
                   $is_slli ? $src1_value << $imm[4:0]:
                   $is_srli ? $src1_value >> $imm[4:0]:
                   $is_and ? $src1_value & $src2_value:
                   $is_or ? $src1_value | $src2_value:
                   $is_xor ? $src1_value ^ $src2_value:
                   $is_sub ? $src1_value -  $src2_value:
                   $is_sll ? $src1_value << $src2_value[4:0]:
                   $is_srl ? $src1_value >> $src2_value[4:0]:
                   $is_sltu ? $sltu_rslt:
                   $is_slti ? $sltiu_rslt:
                   $is_lui ? {$imm[31:12], 12'b0}:
                   $is_auipc ? $pc + $imm:
                   $is_jal ? $pc + 4:
                   $is_jalr ? $pc + 4:
                   $is_slt ? ( ($src1_value[31] == $src2_value[31]) ?
                                    $sltu_rslt :
                                    {31'b0, $src1_value[31]} ) :
                   $is_slti ? ( ($src1_value[31] == $imm[31]) ?
                                    $sltiu_rslt :
                                    {31'b0, $src1_value[31]} ) :
                   $is_sra ? $sra_rslt[31:0]:
                   $is_srai ? $srai_rslt[31:0]:
                   32'b0;
   
   $wr_data[31:0] = $is_load ? $ld_data : $result;
   
   $addr[4:0] = $result[4:0];
   $wr2_en = $is_s_instr;
   $wr2_data[31:0] = $src2_value;
   $rd_en = $is_load;
   $ld_data[31:0] = $rd_data;
   
   
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = 1'b0;
   *failed = *cyc_cnt > M4_MAX_CYC;
   
   m4+rf(32, 32, $reset, $wr_en, $wr_index[4:0], $wr_data[31:0], $rd1_en, $rd1_index[4:0], $rd1_data, $rd2_en, $rd2_index[4:0], $rd2_data)
   m4+dmem(32, 32, $reset, $addr[4:0], $wr_en, $wr_data[31:0], $rd_en, $rd_data)
   m4+cpu_viz()
\SV
   endmodule
