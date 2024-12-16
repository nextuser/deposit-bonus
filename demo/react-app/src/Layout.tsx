import React from "react";
import UserInfoUI from "./UserInfoUI";
import TableUI from "./Table";
import { useState } from "react";
import { BonusPeriodWrapper } from "./contract_types";
const App: React.FC = () => {
  let [period,set_period] = useState<BonusPeriodWrapper|null>(null);

  let change_period = (period : BonusPeriodWrapper|null )=>{
    set_period(period);
  };

  return (
    <div style={{ padding: 20 }}>
      <UserInfoUI onSelectPeriod={change_period}/>
      <TableUI period = {period}/>
    </div>
  );
};

export default App;
