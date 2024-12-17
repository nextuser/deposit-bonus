import { ConnectButton, useCurrentAccount } from "@mysten/dapp-kit";
import { Box, Container, Flex, Heading } from "@radix-ui/themes";
import { useState } from "react";
import Layout from './Layout';
import './index.css';

function App() {
  const currentAccount = useCurrentAccount();
 
  return (
    <>
      <Flex
        position="sticky"
        px="4"
        py="2"
        justify="between"
        style={{
          borderBottom: "1px solid var(--gray-a2)",
        }}
      >
        <Box>
          <Heading style={{ color: '#FFB700' }}>存款利息抽奖</Heading>
        </Box>

        <Box>
          <ConnectButton style={{ backgroundColor: '#FFD700', color: 'black' }} />
        </Box>
      </Flex>

      <Container>
  <div
    style={{
      display: 'flex',
      color: '#FFD700', 
      justifyContent: 'center', 
      alignItems: 'center', 
      height: '100vh', 
      flexDirection: 'column', 
    }}
  >
    {/* 新增简介语句 */}
    <Heading style={{ fontSize: '36px', marginBottom: '20px' }}>欢迎使用我们的存款利息抽奖平台</Heading>
    
    {/* 现有的提示文本 */}
    {currentAccount ? (
      <Layout />
    ) : (
      <Heading>Please connect your wallet to begin</Heading> // 金色字体
    )}
  </div>
</Container>

    </>
  );
}

export default App;
