import { Table, Button, message } from "antd"
import { CopyOutlined } from "@ant-design/icons";
import data from "./services/data";
import copy from "copy-to-clipboard";
import type { ColumnsType } from "antd/es/table";
////import { DataType } from "./services/type";
import { get_records } from "./data-provider";
import { useEffect,useState } from "react";
import { useSuiClient } from "@mysten/dapp-kit";
import { BonusPeriodWrapper, BonusRecord} from "./contract_types";
import { startOfDay } from "date-fns";
const handleCopy = (text: string) => {
  copy(text);
  message.success("地址已复制到剪贴板！");
};
//array join is strange 
const ZERO64 = Array(65).join('0');
function fill(str : string,len :number) : string{
  let start = str.length  ;
  let prefix = ZERO64.slice(0, len - start);
  let result = prefix + str;
  return result ;
}


function hex( p : bigint){
  let str = fill(p.toString(16),64);
  return  "0x" + str;
}
function range(left:bigint,right:bigint){
  return hex(left) + "~" + hex(right);
}

const columns: ColumnsType<BonusRecord> = [
  {
    title: "地址",
    dataIndex: "id",
    key: "id",
    render: (text) => (
      <div>
        <span>{text}</span>
        <Button
          type="link"
          style={{ marginLeft: 8 }}
          onClick={() => handleCopy(text)}
        >
          <CopyOutlined /> 
        </Button>
      </div>
    ),
  },

  {
    title: "中奖时本金",
    dataIndex: "principal",
    key: "principal",
  },

  {
    title: "奖金",
    dataIndex: "gain",
    key: "gain",
  },
];



const TableUI = (props: { period: BonusPeriodWrapper | null }) => {
  let suiClient = useSuiClient();
  let [records, set_records] = useState<BonusRecord[]>([]);
  let hit = 0n;
  let hit_len = 0n;
  let max = 2n ** 256n - 1n;
  let range1 = null;
  let range2 = null;

  if (props.period != null) {
    hit = BigInt(props.period!.seed);
    hit_len = max / 10000n * BigInt(props.period.percent);
    if (hit + hit_len <= max) {
      range1 = range(hit, hit + hit_len);
    } else {
      range1 = range(hit, max);
      range2 = range(0n, hit + hit_len - max);
    }
  }

  useEffect(() => {
    if (props.period) {
      get_records(suiClient, props.period.id.id).then((r) => {
        set_records(r);
        console.log(r);
      });
    }
  }, [props.period]);

  return (
    <div style={{ marginTop: "40px" }}> {/* Add margin here */}
      {range1 ? (
        <div
          style={{
            background: "linear-gradient(90deg, #FFA108, #FEF102)", // 渐变背景
            padding: "20px",
            borderRadius: "10px",
            border: "2px solid #FFA108", // 边框颜色
            width: "fit-content", // 内容宽度自适应
            marginBottom: "20px", // 给下面内容留出间距
            boxShadow: "0 4px 8px rgba(0, 0, 0, 0.1)", // 提升卡片效果
          }}
        >
          <div
            style={{
              fontSize: "16px",
              fontWeight: "bold",
              color: "#333",
              marginBottom: "10px",
            }}
          >
            中奖区域：
          </div>
          <div style={{ fontSize: "14px", fontFamily: "consolas", color: "#333" }}>
            <span>{range1}</span>
            <br />
            {range2 ? (
              <span style={{ fontSize: "14px", fontFamily: "consolas", color: "#333" }}>
                {range2}
              </span>
            ) : null}
          </div>
        </div>
      ) : (
        <span />
      )}

      <Table
        columns={columns}
        dataSource={records}
        rowKey="id"
        pagination={{ pageSize: 3 }}
        style={{
          background: "#fff", // Background for the table
          borderRadius: "10px",
          boxShadow: "0 4px 12px rgba(0, 0, 0, 0.1)", // Box shadow for the table
        }}
        rowClassName="ant-table-row-hover"
        bordered
      />
    </div>
  );
};

export default TableUI;