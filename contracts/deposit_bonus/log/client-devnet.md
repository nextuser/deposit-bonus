# publish package
```bash

export CLOCK=0x6
export RND=0x8
export SYSTEM_STATE=0x5

```

```bash
export ADMIN=0x42a27bbee48b8c97b05540e823e118fe6629bd5d83caf19ef8e9051bf3addf9e
export OPERATOR=0x8f6bd80bca6fb0ac57c0754870b80f2f47d3c4f4e815719b4cda8102cd1bc5b0
export USER_1=0x5e23b1067c479185a2d6f3e358e4c82086032a171916f85dc9783226d7d504de
export USER_2=0x16781b5507cafe0150fe3265357cccd96ff0e9e22e8ef9373edd5e3b4a808884
export USER_3=0xa23b00a9eb52d57b04e80b493385488b3b86b317e875f78e0252dfd1793496bb
```

### devnet 特有
```bash
export VALIDATOR=0x94beb782ccfa172ea8752123e73768757a1f58cfca53928e9ba918a2c44a695b
```
### 发布

```bash

sui client switch  --address $ADMIN
sui client publish --skip-dependency-verification 

```

```bash
export STORAGE=0xebb3101fc3158ecf3e45ae61067d21b329f5571b23623f36ef1c7e2bcc1edd67
export ADMIN_CAP=0x30cb4662625fa617f7ea9ab7cb48c51c53fcc73b432959ab458eb833e13b6960
export OPERATOR_CAP=0xe5790f751b432d7cd933f3a686841ec340eaaf9c7c5b295ea97bcb89d1ab1bee
export HISTORY=0xac6f2b018aec2aefa3fdd8842373330ab994d22b7405724f16234c14a1555f57
export PKG=0x7c9724fd7b372de13cada04283b9699e3d1204bc3a9defe71bbfdf690a54eab7
```




## admin :assign operator
```bash

sui client switch --address $ADMIN
sui client ptb --move-call $PKG::deposit_bonus::assign_operator \
@$ADMIN_CAP @$OPERATOR_CAP @$OPERATOR
```


## user1 deposit
```bash
sui client switch --address $USER_1
sui client faucet 

sui client ptb --split-coins gas [4000000000] --assign new_coin \
 --move-call $PKG::deposit_bonus::deposit \
@$CLOCK @$STORAGE @$SYSTEM_STATE @$VALIDATOR new_coin \
--gas-budget 1000000000
```

## user2 deposit
```bash
sui client switch --address $USER_2
sui client faucet 

sui client ptb --split-coins gas [4000000000] --assign new_coin \
 --move-call $PKG::deposit_bonus::deposit \
@$CLOCK @$STORAGE @$SYSTEM_STATE @$VALIDATOR new_coin \
--gas-budget 1000000000
```

## user3 deposit
```bash
sui client switch --address $USER_3
sui client faucet 
sui client ptb --split-coins gas [2000000000] --assign new_coin \
 --move-call $PKG::deposit_bonus::deposit \
@$CLOCK @$STORAGE @$SYSTEM_STATE @$VALIDATOR new_coin \
--gas-budget 1000000000
```

#  operator donate
```bash
sui client switch --address $OPERATOR
sui client faucet
sui client faucet
sui client faucet
sui client ptb --split-coins gas [2800000000] --assign new_coin \
 --move-call $PKG::deposit_bonus::donate_bonus @$STORAGE new_coin

```

# operator  withdraw and bonus allocate

```bash
sui client switch --address $OPERATOR

sui client ptb --move-call \
$PKG::deposit_bonus::withdraw_and_allocate_bonus @$OPERATOR_CAP \
@$CLOCK @$STORAGE @$SYSTEM_STATE @$RND @$VALIDATOR @$HISTORY
```
# user1  withdraw
```bash
sui client switch --address $USER1
sui client ptb move-call $PKG::deposit_bonus::
```

#   operator  withdraw and bonus allocate
```bash
sui client switch --address $OPERATOR
sui client ptb move-call $PKG::deposit_bonus::
```

sui client switch --address 
sui client switch