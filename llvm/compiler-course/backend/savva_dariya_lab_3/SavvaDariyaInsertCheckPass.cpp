#include "MCTargetDesc/X86BaseInfo.h"
#include "X86.h"
#include "X86InstrInfo.h"
#include "X86Subtarget.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/TargetInstrInfo.h"

using namespace llvm;

namespace {
class SavvaDariyaInsertCheckPass : public MachineFunctionPass {
public:
  static char ID;
  SavvaDariyaInsertCheckPass() : MachineFunctionPass(ID) {}

  bool runOnMachineFunction(MachineFunction &MF) override;

private:
  // Проверка на системные регистры
  bool isSystemReg(Register R) const {
    return R == X86::RSP || R == X86::RBP || R == X86::ESP || R == X86::EBP;
  }

  // Поиск базового регистра в инструкции X86
  Register getBaseAddrReg(const MachineInstr &MI) const {
    const MCInstrDesc &Desc = MI.getDesc();
    int MemOp = X86II::getMemoryOperandNo(Desc.TSFlags);
    if (MemOp < 0) return Register();
    MemOp += X86II::getOperandBias(Desc);
    const MachineOperand &Base = MI.getOperand(MemOp + X86::AddrBaseReg);
    return (Base.isReg() && Base.getReg().isValid()) ? Base.getReg() : Register();
  }
};
} // namespace

char SavvaDariyaInsertCheckPass::ID = 0;

bool SavvaDariyaInsertCheckPass::runOnMachineFunction(MachineFunction &MF) {
  bool Changed = false;
  const X86InstrInfo *TII = MF.getSubtarget<X86Subtarget>().getInstrInfo();

  // 1. Создаем один общий блок для падения (Trap) на всю функцию
  // Это экономит место и упрощает CFG.
  MachineBasicBlock *CommonTrapBB = MF.CreateMachineBasicBlock();
  MF.push_back(CommonTrapBB);
  BuildMI(CommonTrapBB, DebugLoc(), TII->get(X86::TRAP));

  // 2. Собираем инструкции, которые требуют проверки
  SmallVector<MachineInstr *, 16> Targets;
  for (auto &MBB : MF) {
    if (&MBB == CommonTrapBB) continue;
    for (auto &MI : MBB) {
      if (MI.mayLoad() || MI.mayStore()) {
        Register R = getBaseAddrReg(MI);
        if (R && !isSystemReg(R)) Targets.push_back(&MI);
      }
    }
  }

  // 3. Модифицируем код
  for (MachineInstr *MI : Targets) {
    MachineBasicBlock *OrigBB = MI->getParent();
    DebugLoc DL = MI->getDebugLoc();
    Register Ptr = getBaseAddrReg(*MI);

    // --- КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ ТУТ ---
    // Создаем блок продолжения, куда переедет MI и всё, что за ней
    MachineBasicBlock *ContBB = MF.CreateMachineBasicBlock();
    MF.insert(std::next(OrigBB->getIterator()), ContBB);

    // Переносим "хвост" старого блока в новый
    ContBB->splice(ContBB->end(), OrigBB, MI->getIterator(), OrigBB->end());
    
    // Переносим связи (Successors) и PHI-ноды
    ContBB->transferSuccessorsAndUpdatePHIs(OrigBB);

    // Теперь вставляем проверку в OrigBB (теперь он заканчивается тут)
    BuildMI(OrigBB, DL, TII->get(X86::TEST64rr)).addReg(Ptr).addReg(Ptr);

    // JE -> CommonTrapBB (если ноль — прыгаем)
    BuildMI(OrigBB, DL, TII->get(X86::JCC_1))
        .addMBB(CommonTrapBB)
        .addImm(X86::COND_E);

    // Добавляем новые связи в CFG
    OrigBB->addSuccessor(CommonTrapBB);
    OrigBB->addSuccessor(ContBB);
    // -----------------------------------

    Changed = true;
  }

  return Changed;
}

static RegisterPass<SavvaDariyaInsertCheckPass> 
    X("savvadariya-insert-check", "Savva Dariya: inserting a null pointer check", false, false);