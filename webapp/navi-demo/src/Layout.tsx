import React from "react";
import SpaceUI from "./Space";
import TableUI from "./Table";

const App: React.FC = () => {
  return (
    <div style={{ padding: 20 }}>
      <SpaceUI />
      <TableUI />
    </div>
  );
};

export default App;
