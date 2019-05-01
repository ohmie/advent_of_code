defmodule Advent15 do
  defp path(tail), do: Path.expand("data") |> Path.join(tail)
  def read!(file), do: path(file) |> File.read!
  def stream!(file), do: path(file) |> File.stream!

  defmodule Day1 do
    defp elevator("(", acc), do: acc + 1
    defp elevator(")", acc), do: acc - 1
    defp elevator(_, acc), do: acc

    def part1 do
      Advent15.read!("15/1")
      |> String.codepoints
      |> Enum.reduce(0, &elevator/2)
    end

    def part2 do
      Advent15.read!("15/1")
      |> String.codepoints
      |> Enum.map_reduce(0, fn x, acc -> acc = elevator(x, acc); {acc, acc} end)
      |> elem(0)
      |> Enum.find_index(fn x -> x == -1 end)
      |> Kernel.+(1) # Convert 0 indexed to 1 indexed
    end
  end

  defmodule Day2 do
    defp main(func) do
      Advent15.stream!("15/2")
      |> Stream.map(&String.split(&1, "x"))
      |> Stream.map(fn x -> Enum.map(x, &String.to_integer(&1)) end)
      |> Stream.map(fn x -> Enum.sort(x) end)
      |> Stream.map(func)
      |> Enum.sum
    end

    def part1, do: main(fn [x, y, z] -> 2*x*y + 2*y*z + 2*x*z + x*y end)

    def part2, do: main(fn [x, y, z] -> 2*x + 2*y + x*y*z end)
  end

  defmodule Day3 do
    defp fly_dir("<", [h | t]), do: [{elem(h,0)-1, elem(h,1)}, h] ++ t
    defp fly_dir("^", [h | t]), do: [{elem(h,0), elem(h,1)+1}, h] ++ t
    defp fly_dir("v", [h | t]), do: [{elem(h,0), elem(h,1)-1}, h] ++ t
    defp fly_dir(">", [h | t]), do: [{elem(h,0)+1, elem(h,1)}, h] ++ t

    defp main(input) do
      input
      |> Enum.reduce([{0,0}], &fly_dir/2)
      |> Enum.uniq
    end

    defp data, do: Advent15.read!("15/3") |> String.codepoints

    def part1 do
      data()
      |> main
      |> Enum.count
    end

    def part2 do
      santa = data()
      |> Enum.take_every(2)
      |> main

      robo_santa = data()
      |> Enum.drop_every(2)
      |> main

      santa ++ robo_santa
      |> Enum.uniq
      |> Enum.count
    end
  end

  defmodule Day4 do
    defp hash(input, x) do
      :crypto.hash(:md5, input <> x)
      |> Base.encode16(case: :lower)
    end

    defp main(len) do
      input = Advent15.read!("15/4")
      zeroes = String.duplicate("0", len)

      Stream.iterate(1, &(&1 + 1))
      |> Stream.map(&Integer.to_string/1)
      |> Enum.find(fn x -> String.slice(hash(input, x), 0, len) == zeroes end)
    end

    def part1, do: main(5)

    def part2, do: main(6)
  end

  defmodule Day5 do
    def part1 do
      Advent15.stream!("15/5")
      |> Stream.filter(&String.match?(&1, ~r/[aeiou].*[aeiou].*[aeiou]/))
      |> Stream.filter(&String.match?(&1, ~r/(.)\1/))
      |> Stream.reject(&String.contains?(&1, ["ab", "cd", "pq", "xy"]))
      |> Enum.count
    end

    def part2 do
      Advent15.stream!("15/5")
      |> Stream.filter(&String.match?(&1, ~r/(..).*\1/))
      |> Stream.filter(&String.match?(&1, ~r/(.).\1/))
      |> Enum.count
    end
  end

  defmodule Day6 do
    defp set_lights([_, "turn on" | coords], lights) do
      MapSet.union(lights, make_grid(coords))
    end

    defp set_lights([_, "turn off" | coords], lights) do
      MapSet.difference(lights, make_grid(coords))
    end

    defp set_lights([_, "toggle" | coords], lights) do
      grid = make_grid(coords)

      currently_on_lights = grid
      |> Enum.filter(&MapSet.member?(lights, &1))
      |> MapSet.new

      currently_off_lights = grid
      |> Enum.reject(&MapSet.member?(lights, &1))
      |> MapSet.new

      lights = MapSet.difference(lights, currently_on_lights)

      MapSet.union(lights, currently_off_lights)
    end

    defp make_grid(coords) do
      [x1, y1, x2, y2] = coords |> Enum.map(&String.to_integer/1)

      grid = for x <- x1..x2, y <- y1..y2, do: {x, y}
      grid |> MapSet.new
    end

    def part1 do
      Advent15.stream!("15/6")
      |> Stream.map(&Regex.run(~r/(\D+)\s+(\d+),(\d+)\D+(\d+),(\d+)/, &1))
      |> Enum.reduce(MapSet.new(), &set_lights/2)
      |> Enum.count
    end

    defp make_grid_2(coords, default) do
      [x1, y1, x2, y2] = coords |> Enum.map(&String.to_integer/1)
      
      grid = for x <- x1..x2, y <- y1..y2, do: {{x, y}, default}
      grid |> MapSet.new
    end

    defp set_lights_2([_, "turn on" | coords], lights) do
      make_grid_2(coords, 1)
      |> Map.merge(lights, fn _k, v1, v2 -> v1 + v2 end)
    end

    defp set_lights_2([_, "turn off" | coords], lights) do
      make_grid_2(coords, -1)
      |> Map.merge(lights, fn _k, v1, v2 -> max(v1 + v2, 0) end)
    end

    defp set_lights_2([_, "toggle" | coords], lights) do
      make_grid_2(coords, 2)
      |> Map.merge(lights, fn _k, v1, v2 -> v1 + v2 end)
    end

    def part2 do
      grid = make_grid_2(["0", "0", "999", "999"], 0)

      Advent15.stream!("15/6")
      |> Stream.map(&Regex.run(~r/(\D+)\s+(\d+),(\d+)\D+(\d+),(\d+)/, &1))
      |> Enum.reduce(grid, &set_lights_2/2)
      |> Map.values
      |> Enum.sum
    end
  end

  defmodule Day7 do
    use Bitwise
    @sixteen_bit 65536

    def part1() do
      {_, signals} = Advent15.stream!("15/7")
      |> run(%{})

      Map.get(signals, "a")
    end

    def part2() do
      b = part1() |> to_string |> Kernel.<>(" -> b")

      {_, signals} = Advent15.stream!("15/7")
      |> Stream.map(fn instr -> Regex.replace(~r/^\d+ -> b$/, instr, b) end)
      |> run(%{})

      Map.get(signals, "a")
    end

    defp try_execute(instruction, {instructions, signals}) do
      Regex.scan(~r/[a-z]{1,2}/, instruction)
      |> Enum.drop(-1)
      |> List.flatten
      |> Enum.all?(&Map.has_key?(signals, &1))
      |> execute(instruction, {instructions, signals})
    end

    defp execute(false, instruction, {instructions, signals}), do: {instructions ++ [instruction], signals}
    defp execute(true, instruction, {instructions, signals}) do
      cond do
        String.contains?(instruction, "NOT") -> not_instr(instruction, {instructions, signals})
        String.contains?(instruction, "OR") -> or_instr(instruction, {instructions, signals})
        String.contains?(instruction, "AND") -> and_instr(instruction, {instructions, signals})
        String.contains?(instruction, "RSHIFT") -> rshift_instr(instruction, {instructions, signals})
        String.contains?(instruction, "LSHIFT") -> lshift_instr(instruction, {instructions, signals})
        true -> initialize_instr(instruction, {instructions, signals})
      end
    end

    defp initialize_instr(instruction, {instructions, signals}) do
      [_, value_name, signal_name] = Regex.run(~r/([a-z]{1,2}|\d+) -> ([a-z]{1,2})/, instruction)

      {instructions, Map.put(signals, signal_name, get_value(signals, value_name))}
    end

    defp not_instr(instruction, {instructions, signals}) do
      [_, value_name, signal_name] = Regex.run(~r/([a-z]{1,2}) -> ([a-z]{1,2})/, instruction)
      value = @sixteen_bit + ~~~Map.get(signals, value_name)

      {instructions, Map.put(signals, signal_name, value)}
    end

    defp or_instr(instruction, {instructions, signals}) do
      [_, value1_name, value2_name, signal_name] = Regex.run(~r/([a-z]{1,2}) OR ([a-z]{1,2}) -> ([a-z]{1,2})/, instruction)
      value = Map.get(signals, value1_name) ||| Map.get(signals, value2_name)

      {instructions, Map.put(signals, signal_name, value)}
    end

    defp and_instr(instruction, {instructions, signals}) do
      [_, value1_name, value2_name, signal_name] = Regex.run(~r/([a-z]{1,2}|\d+) AND ([a-z]{1,2}) -> ([a-z]{1,2})/, instruction)
      value = get_value(signals, value1_name) &&& Map.get(signals, value2_name)

      {instructions, Map.put(signals, signal_name, value)}
    end

    defp rshift_instr(instruction, {instructions, signals}) do
      [_, value1_name, value2, signal_name] = Regex.run(~r/([a-z]{1,2}) RSHIFT (\d+) -> ([a-z]{1,2})/, instruction)
      value2 = value2 |> String.to_integer
      value = Map.get(signals, value1_name) >>> value2

      {instructions, Map.put(signals, signal_name, value)}
    end

    defp lshift_instr(instruction, {instructions, signals}) do
      [_, value1_name, value2, signal_name] = Regex.run(~r/([a-z]{1,2}) LSHIFT (\d+) -> ([a-z]{1,2})/, instruction)
      value2 = value2 |> String.to_integer
      value = Map.get(signals, value1_name) <<< value2
      value = value &&& (@sixteen_bit - 1)

      {instructions, Map.put(signals, signal_name, value)}
    end

    defp run([], signals), do: {[], signals}
    defp run(instructions, signals) do
      {instructions, signals} = instructions
      |> Enum.reduce({[], signals}, &try_execute/2)

      run(instructions, signals)
    end

    defp get_value(signals, value_name) do
      case Integer.parse(value_name) do
        {i, ""} -> i
        _ -> Map.get(signals, value_name)
      end
    end
  end

  defmodule Day8 do
    @input ~S("\xa8br\x8bjr\"""nq""zjrfcpbktjmrzgsz\xcaqsc\x03n\"huqab""daz\\zyyxddpwk""draes\xa2n\\g\x27ek\"lj\"\\viqych""nnx\\krnrfomdnt\x2flbl\xd2xpo\"cp\"k""kwdaapalq""u\"ptk""ckhorczuiudfjmmcc\\u\"wozqxibsfjma""ydctdrxat\"pd\"lwi\"bjesevfw\xe8""v\"\xa8rrzep\"\"r""nbydghkfvmq\\\xe0\"lfsrsvlsj\"i\x61liif""jsas\"u""odipikxlo""\"rnubsgwltqkbsu\"pcpcs""eitk\\f\\mhcqqoym\\ji""vnedc""\"lhcaurdqzyjyu""haxzsa\"zcn\"y\"foclgtjfcnv\"m\x68krc""\"eoeggg\"tmiydvcay\"vfavc""snqvyqoncwxcvwbdktoywch""rnfgjsyr\xd5wacy""ik\"hebrpvsts""txw""\x15pxtdkogd\"urbm\"gevhh\"nxr\x3erxtk""cetqtcy""inleep\\mgl""uflwbxvww\x2cxzezqnaply\"yh\"qlllzk""eepak\"xqtedzt""na\x61qzfieafvyrsnwkssznohjmc""yceaonylz\xc1\\jrlbbkzwsidfi""ybqafngkcqpbp""\xaft""yidjpaobqydso""ju\\ldxig\\lrdrhjcmm\x77rc""tylacqeslnwj\x48ds\"tjxa""efbfm""\\fxkgoprgdcjgyajykg\\dtbrz""eujvva""h\x7acwfpikme\\vwthyvrqdnx\"""rbpbrxm\\\"\"\"voxx""ykiw\"tkb\\lforu\"rsf\\tf\"x\"rqti""e\\wh\x77aqeugiq\\ihhfqfuaij""g\"t\\o""nxzo\"hf\\xp""dxiaqfo\xea""kali\\zczhiqkqzybjj\"fgdjnik""zdkgrqmdv""bimxim\xb6lrwsaj\"ui\"a""\"rrznitibgx\\olpsjmjqzctxaubdifsq""zb\"khzixaacmhuzmlymoformipdzml""qfwi""hjwsxfpphttjy\"\"zixais\xbblgnqfto""puj\\qmyu\"nqgaqfthbwjokbmrpbhpi""cyxdpkh\\\"""q""m""tbxdzzllarlo""gbtys""gytilk\\vlqxvcuutjunrqc""uugkvcuzan\\eyhb""yaxr\"genlbgw\"\\uc""nrgecjeip\\sjdvgqaqxwsqactopu""pu\"r\"txpyrkfny\\zmwfneyvwmnkkdipv""jm\xa3bhwvq""qxojmnml\"w\x9airr""xbzsuihs\x4dcedy\xaclrhgii\\\"""drgjirusrekrwmvxllwdm""\x28hfxnfpycmpnkku\"csuf\xaarxlqyg\"x""\"zvz\\rmg\"\\sxxoifffyqfyn\"iq\"ps""\"z""zbwkmk\"sgzos\x93gtc\"""bvm\x28aa\\\\\"pywuhaniox\\z\\hbp\xd7mold""aszgvsyna""qf\"vdwuss""lnohni\"qwiacjsjegstlbfq\\kyjhyd""c\\naawulxlqplnacvytspry\xf5ytxxqq""razwqmsqgbaaxcd\\f""radggyrjrg\"zx""\"pu\x11t\\ajcjuieinlkvya""veggiskh""eglfhjxiet\"kouqfskwsy\"hpthsldel""mv\xc1b\"f\\shrssnjwcpmurepdxdlcj""dlayjd\"suvzotgdtc""\xa9pvxeopn""lpplsaxy\"oiwaq""hqwh\\lusv""hykykwlx\"\xa5atkgh\\d\x63dff""vfktanpjy\"xxetc""dnhwkgjnsmsswfuelvihvjl\"jtf""x\"dwvzra\"nbbsewftehczgbvfzd\"rau""csfi\"mzejnjqkqupwadrgti\"von""xckf\xf7xsm\\pgvlpetjndpyblais\\z""yecy\x6fuj\x58bwpgeuiw\"mdu""fgb""c\\lx\x3efthet\xfdelgvwvpem""kgyrmarvfwjinlowt""yzte""vc\"z""sxevqfzmmdwsuu\"""fxbaercmcy\xb6md""f""m\x44gqbcppho\\b""gtafr\x57m\x11jy\"\"erwmmpiwjkbckuw""ufdjt\"kssprzxqixzxmq\x58q""yzbyo\"lfdbyaxexyfbnyv\\\xe8xmre""u\x43ntr\\\\byyfjr\"iveujvnwsqbnpuvrta""us\xf6bai""c\\edh""tzckolphexfq\\\x23\xfbdqv\\\"m""yjafhbvhhj\x1b\"bplb""\"o""rubahvmp\"""qmkukrnrmqumh""wdpxyvyidhwjf\\nabbijwhr\xc5bksvy\"p""u\"prlpg\"""nsvcquyxbwilsxxemf\xd9leq""y\xcetxuafl""it""kwdlysf\\xjpelae""viwh\x58wpjjlnvryuti\x2chngrx\\nhtkui""vhn\x9ehre\xc3ncsqbozms\"nl""ytc\xa3mgeeogjcqavmmmd""xzlexlitseozoxtpzzutfq""cish\x07lmovj""ekbflwqzaiivdr\"pq\\azrfbntqwkn""uc\"xdbegmlmhksofzohavtrnxf""xfdnrdqdrcjzbe""ndg\"ckgrpisib\"rg\"p\\lmpfzlssnvk""witfjwpbyyzlop""zonlww\"emrbcsgdtrg\"rjzy\x64zqntlw""dvgb\"zn\\vrbzema\"ckmd""\\vdlmxhlvldk\"pmzazeip""\"\"r""rsntinv""iy""lr\x20efh""csgexlb\"zqdavlxxhtdbh\"\"\x0fkpvhiphm""ouwhp\"ogbft""cm\\ckltng\"dw\x8brf\xf0eppgckd""zmnlsgalhpkejsizfsbtnfliu\"nhc""pnrkaayqvwpdjbhcrbb\"yfeq\"aq""ozh\\hoxow\x2csrtr\\r\"""bqxabj\"u\\s""cpsjti\"gy""aa\"p\\nki\\ajijkqev""q\"\"lfdentjgd\\""bmokvpoebutfki""pielvcbne\xf6efvzxn""kx""zlgmqagcrbhrwtwtmmg""aiyhmntcqjbpv\xb5hhswxbryoedvos""tdpaxrb""fu\"\x7dttkyvhrlwko""oirc\\\"cqlnqffjqt\\k""edxlia\\tcyby""jpeybgwfayerfrfbvfog\"ol""ysr""bzwzilgwfugjk""tlcc\x75nukvwjgftetjcs\xaecwc""dsqssa\"vzrf\"sewbp\\ahhlmhbeihlh""qtgmjck\"n\"guki\"gmdivwqxismqj""\"f""wuorvlovucngbzdszqpikyk""dfrdsacoukmgvhbq\"\"iwto""\"ey\"ch\\wcgioe\\\"ouvligmsw""ciqlszzgs""\\tzyrkaoi\"sopjaq""lmtnv""ar\"fqoroigiertjjlm\"ymgi\\kkjewsxd""wehcimlvudpxtamdn\"rwy""hr\"zvrwthr\"vruzqfrldn\"b""sggekodkiwvym\"mhsco""ltlkfbrrdvk\\""uut\"sfjnz\"\\ef""hxilg\\""zsredsiwlzrpedibn""vtfi""\\h""qekfrc\xf6wduodbwrguqcng\\n""\"lljlfdrxftwidn\\pkv\xd9ij""mrvgqynpehkliuijlpp""gikjph""yoxcdrdt\"wbaurnyhoyxoihu""onmomwuxuammbzxe""rnrr\\twviz\x61gqaljr\x0dmtw""r\"vupaoi""l""sei""jwxtdtbkd\\kxd""\x22v\\""ahd""j\"bjqxs""\\i\x24gglxub\\nzsajokt""lviwpu\"uxdlh\\zuy\"xqy\"ytdzlx\"r""kptfmys""fwxzikfhczkjwyjszqdbkepaeellc""nlqpsvbrbd\\ns""qryuwkjiodw\"\"vaqyq\"dmyifm""tw\x15kdmaudjl\\zorhp\"alwh""aatrvczesykekkjfyb\"kb""usqcutbqbxxhucwxo\xc1ltb\"j\"bghjcvws""ilhsrnzxkz""bianqfdfdhvw""hqibqs\x7ax\"qoxqoaqtcsz""htxtoojbbauztwxuiq\\ngyfy\\obzc""rxn\\moxlj""mtus\x84erh\"dbe""asx\x50huvsitcxadt""\"bugggtnrc\"\"kl\"hmpu\x83hqrvhpo""ewisbp\"\"vuzf\\w\x5fvalszdhl""scusplpwxfnxu\x57\"zynpn\x99xerc\\ri""m\\kinmkke\x0cl""xhuzit\x7fd""kfbo\x04\x50ruqirn""t\"\"xpbdscmdoug""punvpsgnbgyxe\"sptmpz""bxukkazijr""nxyrcdaoo\"rjkk\"wntehcvcip\"vrd""rdpvqskmihqaw""p\\gwdhtqnpgthod""nwnuf\"\"yebycearom\"nqym\"\xd4sii\xccle""alda\"ptspo\"wkkv\"zoi\"hkb\"vnntyd""ixpgpfzbqv""znui\"\\fzn\x03qozabh\"rva\"pv\x67""e\"zswmwuk""hcccygwfa""ngmace\\rtyllolr\"\x68bw""\\c\"jyufbry\"ryo\"xpo\x26ecninfeckh\\s""hdnpngtuc\"dzbvvosn\x31fwtpzbrt""hesbpd\xd4""dsdbstuzrdfmrnyntufs\"dmv""d\xeeibcwhcvkt""fvzwrsfjdqdmy\"\"v""ns\"dqafz\\lkyoflnazv\"mn\x37\"o\"yj\"e""dypilgbwzccayxa\"bnmuernx""q\xa9ztqrhreb\"\"kxfeyodqb""iz\xa5qjxqulaawuwz\"rqmpcj\\yel""z\"\\pq\"\"y\x67zpjtn""ifxqvivp\"kiiftdoe""jxzebj\"\x35\"qr\"ecglcutuoyywqumcs\"kk""q""yob\x85qmpuwexptczbkrl""cjiavv\"uudpozvibyycnmxhxpxmpjoz""xro\\uiqyrcid""nod\\k""d\"neiec""tqyrqvwyvmz\\pzgzzcqsqsrgbqbtapoz""r\"xvocpeuxfxslgueb\x05kzyyie\"aoec""\"du\\uirlhcbgv\\cjqhfreqnvn""zp\x04\x15\"pbjwhrjtmiba""\\cv\"""k\"rwnb\\hiu\"rqd\"rc\\nyakrhly""klrmafjzandiddodgz""xipzhqzhvlpykzcuppx""zdvrvn\xd0mtfvpylbn\\\\sxcznrzugwznl""ody\\pvm\"kpjiudzhxazirgxzvumeat\"o""kllvhdp\"prjikzrrc\"adgpegc\\\"gk""sqtpug\xbcaauxaamw""wegxxrrxdvpivrqievfeokmnojsk""\\bo""gijhz""ylowluvabwrigssdgtxdwsiorxev\xdd""\"""ghnsrnsqtxpygikahkrl""\"rcfqkbjf\"sgxg\"vnd\\rotn""ap\"smgsuexjrbuqs\"mpbstogj\"x""koaunz\\sgt\"opv""yialiuzwix""yp\"ndxgwzml\"bt""lpcjxmggfsy\\szbxccarjkqzasqkb\xcfd\x0c""x""mgakc""vjieunoh\x73fjwx""erbvv\"qulsd""mimycrbfhqkarmz""tihfbgcszuej\"c\xfbvoqskkhbgpaddioo""mziavkwrmekriqghw""izk\\tnjd\\ed\\emokvjoc""c\"nhbqzndro\\g""usfngdo""aypljdftvptt""ym\"afvq\xbcc""zabi\"wjpvugwhl""ebvptcjqjhc\"n\"p\"dxrphegr\\""mzlqqxokhye\xd9\\rffhnzs""hnipqknwpsjakanuewe""rqgbfcjdrmiz\"h""kzzp\\z\\txmkwaouxictybwx""yzmspjkqrteiydswlvb""gjpxklgpzv\"txri\\hotpuiukzzzd""p\"rxergtbsxmjmkeeqwvoagnki\"""santipvuiq""\"ihjqlhtwbuy\"hdkiv\"mtiqacnf\\""oliaggtqyyx""fwwnpmbb""yrtdrieazfxyyneo""nywbv\\""twc\\ehfqxhgomgrgwpxyzmnkioj""qludrkkvljljd\\xvdeum\x4e")
    @input_2 ~s("\xa8br\x8bjr\"""nq""zjrfcpbktjmrzgsz\xcaqsc\x03n\"huqab""daz\\zyyxddpwk""draes\xa2n\\g\x27ek\"lj\"\\viqych""nnx\\krnrfomdnt\x2flbl\xd2xpo\"cp\"k""kwdaapalq""u\"ptk""ckhorczuiudfjmmcc\\u\"wozqxibsfjma""ydctdrxat\"pd\"lwi\"bjesevfw\xe8""v\"\xa8rrzep\"\"r""nbydghkfvmq\\\xe0\"lfsrsvlsj\"i\x61liif""jsas\"u""odipikxlo""\"rnubsgwltqkbsu\"pcpcs""eitk\\f\\mhcqqoym\\ji""vnedc""\"lhcaurdqzyjyu""haxzsa\"zcn\"y\"foclgtjfcnv\"m\x68krc""\"eoeggg\"tmiydvcay\"vfavc""snqvyqoncwxcvwbdktoywch""rnfgjsyr\xd5wacy""ik\"hebrpvsts""txw""\x15pxtdkogd\"urbm\"gevhh\"nxr\x3erxtk""cetqtcy""inleep\\mgl""uflwbxvww\x2cxzezqnaply\"yh\"qlllzk""eepak\"xqtedzt""na\x61qzfieafvyrsnwkssznohjmc""yceaonylz\xc1\\jrlbbkzwsidfi""ybqafngkcqpbp""\xaft""yidjpaobqydso""ju\\ldxig\\lrdrhjcmm\x77rc""tylacqeslnwj\x48ds\"tjxa""efbfm""\\fxkgoprgdcjgyajykg\\dtbrz""eujvva""h\x7acwfpikme\\vwthyvrqdnx\"""rbpbrxm\\\"\"\"voxx""ykiw\"tkb\\lforu\"rsf\\tf\"x\"rqti""e\\wh\x77aqeugiq\\ihhfqfuaij""g\"t\\o""nxzo\"hf\\xp""dxiaqfo\xea""kali\\zczhiqkqzybjj\"fgdjnik""zdkgrqmdv""bimxim\xb6lrwsaj\"ui\"a""\"rrznitibgx\\olpsjmjqzctxaubdifsq""zb\"khzixaacmhuzmlymoformipdzml""qfwi""hjwsxfpphttjy\"\"zixais\xbblgnqfto""puj\\qmyu\"nqgaqfthbwjokbmrpbhpi""cyxdpkh\\\"""q""m""tbxdzzllarlo""gbtys""gytilk\\vlqxvcuutjunrqc""uugkvcuzan\\eyhb""yaxr\"genlbgw\"\\uc""nrgecjeip\\sjdvgqaqxwsqactopu""pu\"r\"txpyrkfny\\zmwfneyvwmnkkdipv""jm\xa3bhwvq""qxojmnml\"w\x9airr""xbzsuihs\x4dcedy\xaclrhgii\\\"""drgjirusrekrwmvxllwdm""\x28hfxnfpycmpnkku\"csuf\xaarxlqyg\"x""\"zvz\\rmg\"\\sxxoifffyqfyn\"iq\"ps""\"z""zbwkmk\"sgzos\x93gtc\"""bvm\x28aa\\\\\"pywuhaniox\\z\\hbp\xd7mold""aszgvsyna""qf\"vdwuss""lnohni\"qwiacjsjegstlbfq\\kyjhyd""c\\naawulxlqplnacvytspry\xf5ytxxqq""razwqmsqgbaaxcd\\f""radggyrjrg\"zx""\"pu\x11t\\ajcjuieinlkvya""veggiskh""eglfhjxiet\"kouqfskwsy\"hpthsldel""mv\xc1b\"f\\shrssnjwcpmurepdxdlcj""dlayjd\"suvzotgdtc""\xa9pvxeopn""lpplsaxy\"oiwaq""hqwh\\lusv""hykykwlx\"\xa5atkgh\\d\x63dff""vfktanpjy\"xxetc""dnhwkgjnsmsswfuelvihvjl\"jtf""x\"dwvzra\"nbbsewftehczgbvfzd\"rau""csfi\"mzejnjqkqupwadrgti\"von""xckf\xf7xsm\\pgvlpetjndpyblais\\z""yecy\x6fuj\x58bwpgeuiw\"mdu""fgb""c\\lx\x3efthet\xfdelgvwvpem""kgyrmarvfwjinlowt""yzte""vc\"z""sxevqfzmmdwsuu\"""fxbaercmcy\xb6md""f""m\x44gqbcppho\\b""gtafr\x57m\x11jy\"\"erwmmpiwjkbckuw""ufdjt\"kssprzxqixzxmq\x58q""yzbyo\"lfdbyaxexyfbnyv\\\xe8xmre""u\x43ntr\\\\byyfjr\"iveujvnwsqbnpuvrta""us\xf6bai""c\\edh""tzckolphexfq\\\x23\xfbdqv\\\"m""yjafhbvhhj\x1b\"bplb""\"o""rubahvmp\"""qmkukrnrmqumh""wdpxyvyidhwjf\\nabbijwhr\xc5bksvy\"p""u\"prlpg\"""nsvcquyxbwilsxxemf\xd9leq""y\xcetxuafl""it""kwdlysf\\xjpelae""viwh\x58wpjjlnvryuti\x2chngrx\\nhtkui""vhn\x9ehre\xc3ncsqbozms\"nl""ytc\xa3mgeeogjcqavmmmd""xzlexlitseozoxtpzzutfq""cish\x07lmovj""ekbflwqzaiivdr\"pq\\azrfbntqwkn""uc\"xdbegmlmhksofzohavtrnxf""xfdnrdqdrcjzbe""ndg\"ckgrpisib\"rg\"p\\lmpfzlssnvk""witfjwpbyyzlop""zonlww\"emrbcsgdtrg\"rjzy\x64zqntlw""dvgb\"zn\\vrbzema\"ckmd""\\vdlmxhlvldk\"pmzazeip""\"\"r""rsntinv""iy""lr\x20efh""csgexlb\"zqdavlxxhtdbh\"\"\x0fkpvhiphm""ouwhp\"ogbft""cm\\ckltng\"dw\x8brf\xf0eppgckd""zmnlsgalhpkejsizfsbtnfliu\"nhc""pnrkaayqvwpdjbhcrbb\"yfeq\"aq""ozh\\hoxow\x2csrtr\\r\"""bqxabj\"u\\s""cpsjti\"gy""aa\"p\\nki\\ajijkqev""q\"\"lfdentjgd\\""bmokvpoebutfki""pielvcbne\xf6efvzxn""kx""zlgmqagcrbhrwtwtmmg""aiyhmntcqjbpv\xb5hhswxbryoedvos""tdpaxrb""fu\"\x7dttkyvhrlwko""oirc\\\"cqlnqffjqt\\k""edxlia\\tcyby""jpeybgwfayerfrfbvfog\"ol""ysr""bzwzilgwfugjk""tlcc\x75nukvwjgftetjcs\xaecwc""dsqssa\"vzrf\"sewbp\\ahhlmhbeihlh""qtgmjck\"n\"guki\"gmdivwqxismqj""\"f""wuorvlovucngbzdszqpikyk""dfrdsacoukmgvhbq\"\"iwto""\"ey\"ch\\wcgioe\\\"ouvligmsw""ciqlszzgs""\\tzyrkaoi\"sopjaq""lmtnv""ar\"fqoroigiertjjlm\"ymgi\\kkjewsxd""wehcimlvudpxtamdn\"rwy""hr\"zvrwthr\"vruzqfrldn\"b""sggekodkiwvym\"mhsco""ltlkfbrrdvk\\""uut\"sfjnz\"\\ef""hxilg\\""zsredsiwlzrpedibn""vtfi""\\h""qekfrc\xf6wduodbwrguqcng\\n""\"lljlfdrxftwidn\\pkv\xd9ij""mrvgqynpehkliuijlpp""gikjph""yoxcdrdt\"wbaurnyhoyxoihu""onmomwuxuammbzxe""rnrr\\twviz\x61gqaljr\x0dmtw""r\"vupaoi""l""sei""jwxtdtbkd\\kxd""\x22v\\""ahd""j\"bjqxs""\\i\x24gglxub\\nzsajokt""lviwpu\"uxdlh\\zuy\"xqy\"ytdzlx\"r""kptfmys""fwxzikfhczkjwyjszqdbkepaeellc""nlqpsvbrbd\\ns""qryuwkjiodw\"\"vaqyq\"dmyifm""tw\x15kdmaudjl\\zorhp\"alwh""aatrvczesykekkjfyb\"kb""usqcutbqbxxhucwxo\xc1ltb\"j\"bghjcvws""ilhsrnzxkz""bianqfdfdhvw""hqibqs\x7ax\"qoxqoaqtcsz""htxtoojbbauztwxuiq\\ngyfy\\obzc""rxn\\moxlj""mtus\x84erh\"dbe""asx\x50huvsitcxadt""\"bugggtnrc\"\"kl\"hmpu\x83hqrvhpo""ewisbp\"\"vuzf\\w\x5fvalszdhl""scusplpwxfnxu\x57\"zynpn\x99xerc\\ri""m\\kinmkke\x0cl""xhuzit\x7fd""kfbo\x04\x50ruqirn""t\"\"xpbdscmdoug""punvpsgnbgyxe\"sptmpz""bxukkazijr""nxyrcdaoo\"rjkk\"wntehcvcip\"vrd""rdpvqskmihqaw""p\\gwdhtqnpgthod""nwnuf\"\"yebycearom\"nqym\"\xd4sii\xccle""alda\"ptspo\"wkkv\"zoi\"hkb\"vnntyd""ixpgpfzbqv""znui\"\\fzn\x03qozabh\"rva\"pv\x67""e\"zswmwuk""hcccygwfa""ngmace\\rtyllolr\"\x68bw""\\c\"jyufbry\"ryo\"xpo\x26ecninfeckh\\s""hdnpngtuc\"dzbvvosn\x31fwtpzbrt""hesbpd\xd4""dsdbstuzrdfmrnyntufs\"dmv""d\xeeibcwhcvkt""fvzwrsfjdqdmy\"\"v""ns\"dqafz\\lkyoflnazv\"mn\x37\"o\"yj\"e""dypilgbwzccayxa\"bnmuernx""q\xa9ztqrhreb\"\"kxfeyodqb""iz\xa5qjxqulaawuwz\"rqmpcj\\yel""z\"\\pq\"\"y\x67zpjtn""ifxqvivp\"kiiftdoe""jxzebj\"\x35\"qr\"ecglcutuoyywqumcs\"kk""q""yob\x85qmpuwexptczbkrl""cjiavv\"uudpozvibyycnmxhxpxmpjoz""xro\\uiqyrcid""nod\\k""d\"neiec""tqyrqvwyvmz\\pzgzzcqsqsrgbqbtapoz""r\"xvocpeuxfxslgueb\x05kzyyie\"aoec""\"du\\uirlhcbgv\\cjqhfreqnvn""zp\x04\x15\"pbjwhrjtmiba""\\cv\"""k\"rwnb\\hiu\"rqd\"rc\\nyakrhly""klrmafjzandiddodgz""xipzhqzhvlpykzcuppx""zdvrvn\xd0mtfvpylbn\\\\sxcznrzugwznl""ody\\pvm\"kpjiudzhxazirgxzvumeat\"o""kllvhdp\"prjikzrrc\"adgpegc\\\"gk""sqtpug\xbcaauxaamw""wegxxrrxdvpivrqievfeokmnojsk""\\bo""gijhz""ylowluvabwrigssdgtxdwsiorxev\xdd""\"""ghnsrnsqtxpygikahkrl""\"rcfqkbjf\"sgxg\"vnd\\rotn""ap\"smgsuexjrbuqs\"mpbstogj\"x""koaunz\\sgt\"opv""yialiuzwix""yp\"ndxgwzml\"bt""lpcjxmggfsy\\szbxccarjkqzasqkb\xcfd\x0c""x""mgakc""vjieunoh\x73fjwx""erbvv\"qulsd""mimycrbfhqkarmz""tihfbgcszuej\"c\xfbvoqskkhbgpaddioo""mziavkwrmekriqghw""izk\\tnjd\\ed\\emokvjoc""c\"nhbqzndro\\g""usfngdo""aypljdftvptt""ym\"afvq\xbcc""zabi\"wjpvugwhl""ebvptcjqjhc\"n\"p\"dxrphegr\\""mzlqqxokhye\xd9\\rffhnzs""hnipqknwpsjakanuewe""rqgbfcjdrmiz\"h""kzzp\\z\\txmkwaouxictybwx""yzmspjkqrteiydswlvb""gjpxklgpzv\"txri\\hotpuiukzzzd""p\"rxergtbsxmjmkeeqwvoagnki\"""santipvuiq""\"ihjqlhtwbuy\"hdkiv\"mtiqacnf\\""oliaggtqyyx""fwwnpmbb""yrtdrieazfxyyneo""nywbv\\""twc\\ehfqxhgomgrgwpxyzmnkioj""qludrkkvljljd\\xvdeum\x4e")
    
    def part1() do
      String.length(@input) - (String.length(@input_2) - 300 * 2)
    end

    def part2() do
      encoded_length = @input
      |> String.codepoints
      |> Enum.reduce(0, &encode_char/2)

      (encoded_length + 300 * 2) - String.length(@input)
    end

    defp encode_char("\"", acc), do: acc + 2
    defp encode_char("\\", acc), do: acc + 2
    defp encode_char(_, acc), do: acc + 1
  end

  defmodule Day9 do
    def part1, do: main(&Enum.min/1)

    def part2, do: main(&Enum.max/1)

    defp main(func) do
      route_distances = Advent15.stream!("15/9")
      |> Stream.map(&Regex.run(~r/(\S+) to (\S+) = (\d+)/, &1))
      |> Enum.reduce(%{}, &parse_route_distance/2)

      Advent15.stream!("15/9")
      |> get_unique_names(~r/(\S+) to (\S+)/)
      |> permutations
      |> Enum.map(&calc_distance(&1, route_distances))
      |> func.()
    end

    defp parse_route_distance(route_list, route_distances) do
      [_, city1, city2, distance] = route_list
      distance = String.to_integer(distance)

      # Add routes both ways for easy lookup
      route_distances = Map.put(route_distances, city1 <> city2, distance)
      Map.put(route_distances, city2 <> city1, distance)
    end

    def permutations([]), do: [[]]
    def permutations(list), do: for h <- list, t <- permutations(list -- [h]), do: [h | t]

    def get_unique_names(input, regex) do
      input
      |> Stream.map(&Regex.run(regex, &1))
      |> Enum.map(fn [_ | t] -> t end)
      |> List.flatten
      |> Enum.uniq
    end

    defp calc_distance(route, route_distances) do
      Enum.chunk_every(route, 2, 1, :discard)
      |> Enum.reduce(0, fn [city1, city2], acc -> acc + Map.get(route_distances, city1 <> city2) end)
    end
  end

  defmodule Day10 do
    def part1, do: main(40)

    def part2, do: main(50)

    defp main(times) do
      input = Advent15.read!("15/10")

      1..times
      |> Enum.reduce(input, fn _, acc -> look_and_say(acc) end)
      |> String.length
    end

    defp look_and_say(input, output \\ "")
    defp look_and_say("", output), do: output
    defp look_and_say(input, output) do
      [run, char] = case Regex.run(~r/^(\d)\1+/, input) do
        [run, char] -> [run, char]
        _ -> [String.at(input, 0), String.at(input, 0)]
      end

      look_and_say(String.trim_leading(input, char), output <> Integer.to_string(String.length(run)) <> char)
    end
  end

  defmodule Day11 do
    def part1, do: main(Advent15.read!("15/11"))

    def part2, do: main(Advent15.read!("15/11")) |> main

    defp main(input) do
      consecutive_chars_regex = ?a..?z
      |> Enum.chunk_every(3, 1, :discard)
      |> Enum.map(&to_string/1)
      |> Enum.join("|")
      |> Regex.compile!

      input
      |> string_to_int
      |> Kernel.+(1)
      |> Stream.iterate(&(&1 + 1))
      |> Stream.map(&int_to_string/1)
      |> Stream.reject(&String.contains?(&1, ["i","o","l"]))
      |> Stream.filter(&Regex.match?(~r/(.)\1.*(.)\2/, &1))
      |> Stream.filter(&Regex.match?(consecutive_chars_regex, &1))
      |> Enum.take(1)
      |> hd
    end

    defp string_to_int(string) do
      string
      |> String.to_charlist
      |> Enum.map(fn x -> x - ?a end)
      |> Integer.undigits(26)
    end

    defp int_to_string(int) do
      int
      |> Integer.digits(26)
      |> Enum.map(fn x -> x + ?a end)
      |> to_string
    end
  end

  defmodule Day12 do
    def part1(input \\ Advent15.read!("15/12")) do
      Regex.scan(~r/-?\d+/, input)
      |> List.flatten
      |> Stream.map(&String.to_integer/1)
      |> Enum.sum
    end

    def part2 do
      Advent15.read!("15/12")
      |> Jason.decode!
      |> remove_red
      |> Jason.encode!
      |> part1
    end

    defp remove_red(list) when is_list(list) do
      list
      |> Enum.map(&remove_red/1)
    end
    defp remove_red(map) when is_map(map) do
      has_red = map
      |> Map.values
      |> Enum.any?(fn x -> x == "red" end)

      if has_red do
        %{}
      else
        map
        |> Map.to_list
        |> Enum.reduce(%{}, fn {k, v}, map -> Map.put(map, k, remove_red(v)) end)
      end
    end
    defp remove_red(x), do: x
  end

  defmodule Day13 do
    def part1(extra_names \\ []) do
      happiness_inputs = Advent15.stream!("15/13")
      |> Stream.map(&Regex.run(~r/(\S+) would (gain|lose) (\d+) happiness units by sitting next to (\S+)./, &1))
      |> Enum.reduce(%{}, &parse_happiness_input/2)

      Advent15.stream!("15/13")
      |> Day9.get_unique_names(~r/(\S+) would .* to (\S+)./)
      |> Kernel.++(extra_names)
      |> Day9.permutations
      |> Enum.map(fn [h | t] -> [h | t] ++ [h] end)
      |> Enum.map(&calc_happiness(&1, happiness_inputs))
      |> Enum.max
    end

    def part2, do: part1(["Me"])

    defp parse_happiness_input(happiness_list, happiness_map) do
      [_, name1, mod, amount, name2] = happiness_list
      amount = case mod do
        "lose" -> "-" <> amount
        _ -> amount
      end

      Map.put(happiness_map, name1 <> name2, String.to_integer(amount))
    end

    defp calc_happiness(table, happiness_inputs) do
      Enum.chunk_every(table, 2, 1, :discard)
      |> Enum.reduce(0, fn [name1, name2], acc -> acc + Map.get(happiness_inputs, name1 <> name2, 0) + Map.get(happiness_inputs, name2 <> name1, 0) end)
    end
  end

  defmodule Day14 do
    defmodule DeerStats, do: defstruct name: "", speed: 0, flight_time: 0, rest_time: 0, state: :fly, time_left: 0, distance: 0, score: 0

    def part1 do
      Advent15.stream!("15/14")
      |> Stream.map(&Regex.run(~r/(\S+) can fly (\d+) km\/s for (\d+) seconds, but then must rest for (\d+) seconds./, &1))
      |> Stream.map(&parse_stats/1)
      |> Stream.map(&fly(&1, 2503))
      |> Enum.max
    end

    defp fly(deer_stats, time) do
      cond do
        time > deer_stats.flight_time -> deer_stats.speed * deer_stats.flight_time + rest(deer_stats, time - deer_stats.flight_time)
        true -> deer_stats.speed * time
      end
    end

    defp rest(deer_stats, time) do
      cond do
        time > deer_stats.rest_time -> fly(deer_stats, time - deer_stats.rest_time)
        true -> 0
      end
    end

    defp parse_stats(stats_list) do
      [_, name, speed, flight_time, rest_time] = stats_list

      %DeerStats{
        name: name,
        speed: String.to_integer(speed),
        flight_time: String.to_integer(flight_time),
        rest_time: String.to_integer(rest_time),
        time_left: flight_time
      }
    end

    def part2 do
      deer_stats = Advent15.stream!("15/14")
      |> Stream.map(&Regex.run(~r/(\S+) can fly (\d+) km\/s for (\d+) seconds, but then must rest for (\d+) seconds./, &1))
      |> Enum.map(&parse_stats/1)

      1..2503
      |> Enum.reduce(deer_stats, fn _, deer_stats -> step_all(deer_stats) end)
      |> Enum.reduce(0, fn stats, max -> Enum.max([stats.score, max]) end)
    end

    defp step_all(deer_stats) do
      deer_stats = deer_stats
      |> Enum.map(&step/1)

      max = deer_stats
      |> Enum.reduce(0, fn stats, max -> Enum.max([stats.distance, max]) end)

      deer_stats
      |> Enum.map(&score(&1, max))
    end

    defp step(stats) do
      stats = %{stats | time_left: stats.time_left - 1}

      stats = if stats.state == :fly do
        %{stats | distance: stats.distance + stats.speed}
      else
        stats
      end

      case {stats.state, stats.time_left} do
        {:fly, 0} ->
          stats = %{stats | state: :rest}
          %{stats | time_left: stats.rest_time}
        {:rest, 0} ->
          stats = %{stats | state: :fly}
          %{stats | time_left: stats.flight_time}
        _ -> stats
      end
    end

    defp score(stats, max) do
      if stats.distance == max do
        %{stats | score: stats.score + 1}
      else
        stats
      end
    end
  end

  defmodule Day15 do
    defmodule Ingredient, do: defstruct name: "", capacity: 0, durability: 0, flavor: 0, texture: 0, calories: 0

    def part1(calories? \\ false) do
      ingredients = Advent15.stream!("15/15")
      |> Stream.map(&Regex.run(~r/(\S+): capacity (-?\d+), durability (-?\d+), flavor (-?\d+), texture (-?\d+), calories (-?\d+)/, &1))
      |> Enum.map(&parse_ingredients/1)

      measurements = for a <- 0..100, b <- 0..100, c <- 0..100, d <- 0..100, a+b+c+d==100, do: {a, b, c, d}

      measurements
      |> Enum.reduce(0, fn measurement, max -> Enum.max([calc_score(ingredients, measurement, calories?), max]) end)
    end

    def part2, do: part1(true)

    defp parse_ingredients(ingredients_list) do
      [_, name, capacity, durability, flavor, texture, calories] = ingredients_list

      %Ingredient{
        name: name,
        capacity: String.to_integer(capacity),
        durability: String.to_integer(durability),
        flavor: String.to_integer(flavor),
        texture: String.to_integer(texture),
        calories: String.to_integer(calories)
      }
    end

    defp calc_score(ingredients, measurement, calories?) do
      sprinkles = Enum.at(ingredients, 0)
      butterscotch = Enum.at(ingredients, 1)
      chocolate = Enum.at(ingredients, 2)
      candy = Enum.at(ingredients, 3)

      capacity = sprinkles.capacity * elem(measurement, 0) + butterscotch.capacity * elem(measurement, 1) + chocolate.capacity * elem(measurement, 2) + candy.capacity * elem(measurement, 3)
      capacity = Enum.max([capacity, 0])

      durability = sprinkles.durability * elem(measurement, 0) + butterscotch.durability * elem(measurement, 1) + chocolate.durability * elem(measurement, 2) + candy.durability * elem(measurement, 3)
      durability = Enum.max([durability, 0])

      flavor = sprinkles.flavor * elem(measurement, 0) + butterscotch.flavor * elem(measurement, 1) + chocolate.flavor * elem(measurement, 2) + candy.flavor * elem(measurement, 3)
      flavor = Enum.max([flavor, 0])

      texture = sprinkles.texture * elem(measurement, 0) + butterscotch.texture * elem(measurement, 1) + chocolate.texture * elem(measurement, 2) + candy.texture * elem(measurement, 3)
      texture = Enum.max([texture, 0])
      
      calories = sprinkles.calories * elem(measurement, 0) + butterscotch.calories * elem(measurement, 1) + chocolate.calories * elem(measurement, 2) + candy.calories * elem(measurement, 3)
      calories_score = case {calories?, calories} do
        {false, _} -> 1
        {true, 500} -> 1
        {true, _} -> 0
      end

      capacity * durability * flavor * texture * calories_score
    end
  end

  defmodule Day16 do
    @input %{children: 3, cats: 7, samoyeds: 2, pomeranians: 3, akitas: 0, vizslas: 0, goldfish: 5, trees: 3, cars: 2, perfumes: 1}

    defp main do
      Advent15.stream!("15/16")
      |> Stream.map(&Regex.run(~r/Sue (\d+): (\S+): (\d+), (\S+): (\d+), (\S+): (\d+)/, &1))
      |> Stream.map(fn [_, sue_num, key1, value1, key2, value2, key3, value3] ->
        map = %{}
        |> Map.put(key1, String.to_integer(value1))
        |> Map.put(key2, String.to_integer(value2))
        |> Map.put(key3, String.to_integer(value3))

        %{sue_num: sue_num, map: map}
      end)
      |> Stream.filter(fn sue -> Map.get(sue.map, "children", @input.children) == @input.children end)
      |> Stream.filter(fn sue -> Map.get(sue.map, "samoyeds", @input.samoyeds) == @input.samoyeds end)
      |> Stream.filter(fn sue -> Map.get(sue.map, "akitas", @input.akitas) == @input.akitas end)
      |> Stream.filter(fn sue -> Map.get(sue.map, "vizslas", @input.vizslas) == @input.vizslas end)
      |> Stream.filter(fn sue -> Map.get(sue.map, "cars", @input.cars) == @input.cars end)
      |> Stream.filter(fn sue -> Map.get(sue.map, "perfumes", @input.perfumes) == @input.perfumes end)
    end

    def part1 do
      main()
      |> Stream.filter(fn sue -> Map.get(sue.map, "cats", @input.cats) == @input.cats end)
      |> Stream.filter(fn sue -> Map.get(sue.map, "pomeranians", @input.pomeranians) == @input.pomeranians end)
      |> Stream.filter(fn sue -> Map.get(sue.map, "goldfish", @input.goldfish) == @input.goldfish end)
      |> Stream.filter(fn sue -> Map.get(sue.map, "trees", @input.trees) == @input.trees end)
      |> Enum.at(0)
      |> Map.get(:sue_num)
    end

    def part2 do
      main()
      |> Stream.filter(fn sue -> Map.get(sue.map, "cats", @input.cats+1) > @input.cats end)
      |> Stream.filter(fn sue -> Map.get(sue.map, "pomeranians", @input.pomeranians-1) < @input.pomeranians end)
      |> Stream.filter(fn sue -> Map.get(sue.map, "goldfish", @input.goldfish-1) < @input.goldfish end)
      |> Stream.filter(fn sue -> Map.get(sue.map, "trees", @input.trees+1) > @input.trees end)
      |> Enum.at(0)
      |> Map.get(:sue_num)
    end
  end

  defmodule Day17 do
    def part1 do
      Advent15.stream!("15/17")
      |> Enum.map(fn i -> {i, _} = Integer.parse(i); i end)
      |> calc([], 0)
    end
    
    defp calc(_, _, subtotal) when subtotal == 150, do: 1
    defp calc(_, _, subtotal) when subtotal > 150, do: 0
    defp calc([], _, subtotal) when subtotal < 150, do: 0
    defp calc(input_containers, test_solution, subtotal) when subtotal < 150 do
      0..(length(input_containers)-1)
      |> Enum.to_list
      |> Enum.reduce(0, fn i, acc ->
        container = Enum.at(input_containers, i)
        acc + calc(Enum.drop(input_containers, i+1), [container | test_solution], subtotal + container)
      end)
    end

    def part2 do
      solutions = Advent15.stream!("15/17")
      |> Enum.map(fn i -> {i, _} = Integer.parse(i); i end)
      |> calc2([], 0)

      min_solution_length = solutions
      |> Enum.reduce(fn x, acc -> Enum.min([length(x), acc]) end)

      solutions
      |> Enum.filter(fn x -> length(x) == min_solution_length end)
      |> length
    end
    
    defp calc2(_, solution, subtotal) when subtotal == 150, do: [solution]
    defp calc2(_, _, subtotal) when subtotal > 150, do: []
    defp calc2([], _, subtotal) when subtotal < 150, do: []
    defp calc2(input_containers, test_solution, subtotal) when subtotal < 150 do
      0..(length(input_containers)-1)
      |> Enum.to_list
      |> Enum.reduce([], fn i, acc ->
        container = Enum.at(input_containers, i)
        acc ++ calc2(Enum.drop(input_containers, i+1), [container | test_solution], subtotal + container)
      end)
    end
  end

  defmodule Day18 do
    def part1, do: main(&step/2)
    def part2, do: main(&step2/2)

    defp main(step) do
      input = Advent15.stream!("15/18")
      |> Enum.map(&String.codepoints/1)
      
      grid = for x <- 0..99, y <- 0..99, Enum.at(Enum.at(input, y), x) == "#", do: {x, y}
      grid = MapSet.new(grid)

      1..100
      |> Enum.reduce(grid, step)
      |> Enum.count
    end

    defp step(_, grid) do
      grid = for x <- 0..99, y <- 0..99, look_around_light(grid, x, y), do: {x, y}
      grid |> MapSet.new
    end

    defp step2(x, grid) do
      step(x, add_corners(grid))
      |> add_corners
    end

    defp add_corners(grid), do: grid |> MapSet.put({0,0}) |> MapSet.put({99,0}) |> MapSet.put({0,99}) |> MapSet.put({99,99})

    defp look_around_light(grid, x, y) do
      neighbors_on = [
        light_on?(grid, {x-1, y-1}),
        light_on?(grid, {x-1, y+0}),
        light_on?(grid, {x-1, y+1}),
        light_on?(grid, {x+0, y-1}),
        
        light_on?(grid, {x+0, y+1}),
        light_on?(grid, {x+1, y-1}),
        light_on?(grid, {x+1, y+0}),
        light_on?(grid, {x+1, y+1})
      ]
      |> Enum.filter(fn bool -> bool end)
      |> Enum.count

      check_light_state(light_on?(grid, {x, y}), neighbors_on)
    end

    defp light_on?(grid, {0, 0}), do: MapSet.member?(grid, {0, 0})
    defp light_on?(grid, {1, 0}), do: MapSet.member?(grid, {1, 0})
    defp light_on?(grid, {0, 1}), do: MapSet.member?(grid, {0, 1})
    defp light_on?(grid, {1, 1}), do: MapSet.member?(grid, {1, 1})
    defp light_on?(grid, {x, y}), do: MapSet.member?(grid, {x, y})

    defp check_light_state(false, 3), do: true
    defp check_light_state(true, 2), do: true
    defp check_light_state(true, 3), do: true
    defp check_light_state(_, _), do: false
  end

  defmodule Day19 do
    def part1 do
      molecule = Advent15.read!("15/19-2")

      Advent15.stream!("15/19-1")
      |> Stream.map(&Regex.run(~r/(\S+) => (\S+)/, &1))
      |> Enum.map(&generate_transforms(&1, molecule))
      |> List.flatten
      |> Enum.uniq
      |> List.delete(molecule)
      |> Enum.count
    end

    defp generate_transforms([_, from, to], molecule) do
      split_molecule = molecule
      |> String.split(from)
      |> Enum.intersperse(from)

      1..(length(split_molecule) - 1)
      |> Stream.take_every(2)
      |> Stream.map(&List.replace_at(split_molecule, &1, to))
      |> Enum.map(&Enum.join/1)
    end

    def part2_concept_test do
      molecule = Advent15.read!("15/19-2")

      # Ca are ignored deleted because that is the only thing it can do. They are still counted as steps, though.
      {molecule, depth} = {molecule, 0}
      |> simple_replace("Ca")
      |> simple_replace("SiRnFYFAr", "Ca")
      |> simple_replace("PMg", "F")
      |> simple_replace("PRnFAr", "Ca")
      |> simple_replace("Ca")
      |> simple_replace("SiRnFYFAr", "Ca")
      |> simple_replace("SiRnFAr", "P")
      |> simple_replace("PTi", "P")
      |> simple_replace("PTi", "P")
      |> simple_replace("PB", "Ca")
      |> simple_replace("Ca")
      |> simple_replace("SiTh", "Ca")
      |> simple_replace("Ca")
      |> simple_replace("SiRnMgAr", "Ca")
      |> simple_replace("Ca")
      |> simple_replace("SiRnFYFAr", "Ca")
      |> simple_replace("Ca")

      depth + two_to_one_steps(molecule)
    end

    def part2 do
      # The molecule starts with one C, and no Hs, Os, or Ns.
      # Because the molecules only convert to each other there can only be one of them at a time.
      # So ignoring those the step that removes the most elements per step is SiRnFYFAr -> Ca.
      # There are a limited number of Ys in the molecule. If they be arranged into FYF we can use our Ys on our best step.
      # The concept test was used to verify this as possible.
      # This remove twice as many Fs as Ys, assuming we are always able to use our best step and then does simple 2 element for 1 steps for the rest.
      molecule = Advent15.read!("15/19-2")
      num_ys = Regex.scan(~r/Y/, molecule) |> Enum.count
      molecule = String.replace(molecule, "Y", "")
      molecule = 1..num_ys
      |> Enum.reduce(molecule, fn _, molecule -> String.replace(molecule, "F", "", global: false) end)
      
      two_to_one_steps(molecule)
    end

    defp two_to_one_steps(molecule) do
      # Ar and Rn always come in pairs are removed. They can be ignored.
      # I'm using a count of the capital letters to find the number of elements.
      # This is assuming each step moves removes one element in a simple 2 -> 1 fashion.
      count = Regex.scan(~r/[A-Z]/, String.replace(molecule, ["Ar","Rn"], "")) |> Enum.count
      # The step of e to first molecule makes a molecule with 2 elements, the second step makes a molecule with 3 elements.
      # Therefore, subtract 1 from the number of elements to get the steps.
      count - 1
    end

    defp simple_replace({molecule, depth}, from, to \\ "") do
      regex = Regex.compile!(from)

      depth = depth + (Regex.scan(regex, molecule) |> Enum.count)
      molecule = Regex.replace(regex, molecule, to)
      {molecule, depth}
    end
  end

  defmodule Day20 do
    # This is very slow
    defp main(present_per_house, elf_strategy) do
      presents_num = Advent15.read!("15/20") |> String.to_integer

      1..presents_num
      |> Enum.reduce_while(0, fn house_num, _ ->
        if calc_house(house_num, present_per_house, elf_strategy) >= presents_num, do: {:halt, house_num}, else: {:cont, house_num}
      end)
    end

    def part1, do: main(10, &elf_strategy_1/2)
    def part2, do: main(11, &elf_strategy_2/2)

    defp calc_house(house_num, presents_per_house, elf_strategy) do
      1..house_num
      |> Enum.reduce(0, fn elf_num, acc -> 
        acc + elf_strategy.(house_num, elf_num)
      end)
      |> Kernel.*(presents_per_house)
    end

    defp elf_strategy_1(house_num, elf_num) do
      case rem(house_num, elf_num) do
        0 -> elf_num
        _ -> 0
      end 
    end

    defp elf_strategy_2(house_num, elf_num) do
      if house_num <= elf_num * 50, do: elf_strategy_1(house_num, elf_num), else: 0
    end
  end

  defmodule Day21 do
    def part1, do: main(&(&1.price < &2.price), &Kernel.>=/2)
    def part2, do: main(&(&1.price > &2.price), &Kernel.</2)

    defp main(sort, win_condition) do
      weapons = parse_items("15/21-1")
      armors = parse_items("15/21-2")
      rings = parse_items("15/21-3")

      boss = %{}
      |> Map.put(:hp, parse_boss_stats("15/21-4", "Hit Points"))
      |> Map.put(:damage, parse_boss_stats("15/21-4", "Damage"))
      |> Map.put(:armor, parse_boss_stats("15/21-4", "Armor"))

      for weapon <- 1..Enum.count(weapons), armor <- 1..Enum.count(armors), ring1 <- 1..Enum.count(rings), ring2 <- 1..Enum.count(rings), ring1 != ring2 do
        weapon = Enum.at(weapons, weapon - 1)
        armor = Enum.at(armors, armor - 1)
        ring1 = Enum.at(rings, ring1 - 1)
        ring2 = Enum.at(rings, ring2 - 1)
        %{
          name: weapon.name <> "/" <> armor.name <> "/" <> ring1.name <> "/" <> ring2.name,
          price: weapon.price + armor.price + ring1.price + ring2.price,
          damage: weapon.damage + armor.damage + ring1.damage + ring2.damage,
          armor: weapon.armor + armor.armor + ring1.armor + ring2.armor
        }
      end
      |> Enum.sort(sort)
      |> Enum.find(&player_survives?(&1, boss, win_condition))
      |> Map.get(:price)
    end

    defp parse_items(input_file) do
      Advent15.stream!(input_file)
      |> Stream.map(&Regex.run(~r/(.+?)\s+(\d+)\s+(\d+)\s+(\d+)/, &1))
      |> Stream.filter(&(&1))
      |> Enum.map(fn [_, name, price, damage, armor] ->
        %{name: name, price: String.to_integer(price), damage: String.to_integer(damage), armor: String.to_integer(armor)} 
      end)
    end

    def parse_boss_stats(file, stat_name) do
      [_, stat] = Regex.compile!(stat_name <> ": (\\d+)") |> Regex.run(Advent15.read!(file))
      String.to_integer(stat)
    end

    defp player_survives?(player, boss, win_condition) do
      player_attack = player.damage - boss.armor
      player_attack = Enum.max([1, player_attack])

      boss_attack = boss.damage - player.armor
      boss_attack = Enum.max([1, boss_attack])
      win_condition.(div(100, boss_attack), div(boss.hp, player_attack))
    end
  end

  defmodule Day22 do
    def part2, do: part1(&hard_mode/1)

    def part1(hard_mode \\ & &1) do
      player = %{
        hp: 50,
        mana: 500,
        spent_mana: 0,
        outcome: :ongoing
      }

      boss = %{
        hp: Advent15.Day21.parse_boss_stats("15/22", "Hit Points"),
        damage: Advent15.Day21.parse_boss_stats("15/22", "Damage"),
        default_damage: Advent15.Day21.parse_boss_stats("15/22", "Damage")
      }

      active_spells = %{
        magic_missile: 0,
        drain: 0,
        shield: 0,
        poison: 0,
        recharge: 0
      }

      try_turns({player, boss, active_spells}, hard_mode)
      |> Enum.map(fn {player, _, _} -> player.spent_mana end)
      |> Enum.min
    end

    defp try_turns({player, boss, active_spells}, hard_mode) do
      Map.keys(active_spells)
      |> Enum.filter(&(Map.get(active_spells, &1) == 0))
      |> Enum.map(&turn({player, boss, active_spells}, &1, hard_mode))
      |> Enum.reject(fn {player, _, _} -> player.outcome == :lose end)
      |> Enum.reject(fn {player, _, _} -> player.spent_mana > 1500 end)
      |> Enum.flat_map(fn {player, boss, active_spells} ->
        case player.outcome do
          :win -> [{player, boss, active_spells}]
          _ -> try_turns({player, boss, active_spells}, hard_mode)
        end
      end)
    end

    defp turn(state, spell, hard_mode) do
      state
      |> hard_mode.()
      |> player_turn(spell)
      |> before_turn
      |> boss_turn
      |> before_turn
    end

    defp before_turn({player, boss, active_spells}) do
      player = if player.hp <= 0 && player.outcome == :ongoing do
        %{player | :outcome => :lose}
      else
        player
      end

      boss = if active_spells.shield > 0 do
        %{boss | :damage => boss.default_damage - 7}
      else
        %{boss | :damage => boss.default_damage}
      end
      active_spells = update_active_spell(active_spells, :shield)

      boss = if active_spells.poison > 0 do
        %{boss | :hp => boss.hp - 3}
      else
        boss
      end
      active_spells = update_active_spell(active_spells, :poison)

      player = if active_spells.recharge > 0 do
        %{player | :mana => player.mana + 101}
      else
        player
      end
      active_spells = update_active_spell(active_spells, :recharge)

      player = if boss.hp <= 0 && player.outcome == :ongoing do
        %{player | :outcome => :win}
      else
        player
      end

      {player, boss, active_spells}
    end

    defp player_turn({player, boss, active_spells}, :magic_missile) do
      player = charge_mana(player, 53)
      boss = %{boss | :hp => boss.hp - 4}
      {player, boss, active_spells}
    end

    defp player_turn({player, boss, active_spells}, :drain) do
      player = charge_mana(player, 73)
      boss = %{boss | :hp => boss.hp - 2}
      player = %{player | :hp => player.hp + 2}
      {player, boss, active_spells}
    end

    defp player_turn({player, boss, active_spells}, :shield) do
      player = charge_mana(player, 113)
      active_spells = add_active_spell(active_spells, :shield, 6)
      {player, boss, active_spells}
    end

    defp player_turn({player, boss, active_spells}, :poison) do
      player = charge_mana(player, 173)
      active_spells = add_active_spell(active_spells, :poison, 6)
      {player, boss, active_spells}
    end

    defp player_turn({player, boss, active_spells}, :recharge) do
      player = charge_mana(player, 229)
      active_spells = add_active_spell(active_spells, :recharge, 5)
      {player, boss, active_spells}
    end

    defp boss_turn({player, boss, active_spells}) do
      player = %{player | :hp => player.hp - boss.damage}
      {player, boss, active_spells}
    end

    defp add_active_spell(active_spells, spell, turns) do
      %{active_spells | spell => turns}
    end

    defp update_active_spell(active_spells, spell) do
      if active_spells[spell] > 0, do: %{active_spells | spell => active_spells[spell] - 1}, else: active_spells
    end

    defp charge_mana(player, amount) do
      player = %{player | :mana => player.mana - amount}
      player = %{player | :spent_mana => player.spent_mana + amount}

      if player.mana < 0 && player.outcome == :ongoing do
        %{player | :outcome => :lose}
      else
        player
      end
    end

    defp hard_mode({player, boss, active_spells}) do
      player = %{player | :hp => player.hp - 1}

      player = if player.hp <= 0 && player.outcome == :ongoing do
        %{player | :outcome => :lose}
      else
        player
      end
      {player, boss, active_spells}
    end
  end

  defmodule Day23 do
    def part1, do: main(%{"a" => 0, "b" => 0})
    def part2, do: main(%{"a" => 1, "b" => 0})

    defp main(registers) do
      instructions = Advent15.stream!("15/23")
      |> Enum.map(&({String.to_atom(String.slice(&1, 0..2)), String.slice(&1, 4..-2)}))

      instruction = Enum.at(instructions, 0)
      run_instruction(instructions, instruction, 0, registers)
    end

    defp run_instruction(_, nil, _, registers) do
      registers
    end

    defp run_instruction(instructions, {:hlf, reg}, pointer, registers) do
      registers = Map.put(registers, reg, div(registers[reg], 2))
      pointer = pointer + 1

      instruction = Enum.at(instructions, pointer)
      run_instruction(instructions, instruction, pointer, registers)
    end

    defp run_instruction(instructions, {:tpl, reg}, pointer, registers) do
      registers = Map.put(registers, reg, registers[reg] * 3)
      pointer = pointer + 1

      instruction = Enum.at(instructions, pointer)
      run_instruction(instructions, instruction, pointer, registers)
    end

    defp run_instruction(instructions, {:inc, reg}, pointer, registers) do
      registers = Map.put(registers, reg, registers[reg] + 1)
      pointer = pointer + 1

      instruction = Enum.at(instructions, pointer)
      run_instruction(instructions, instruction, pointer, registers)
    end

    defp run_instruction(instructions, {:jmp, amount}, pointer, registers) do
      pointer = pointer + String.to_integer(amount)

      instruction = Enum.at(instructions, pointer)
      run_instruction(instructions, instruction, pointer, registers)
    end

    defp run_instruction(instructions, {:jie, vars}, pointer, registers) do
      [reg, amount] = String.split(vars, ", ")
      pointer = if rem(registers[reg], 2) == 0 do
        pointer + String.to_integer(amount)
      else
        pointer + 1
      end

      instruction = Enum.at(instructions, pointer)
      run_instruction(instructions, instruction, pointer, registers)
    end

    defp run_instruction(instructions, {:jio, vars}, pointer, registers) do
      [reg, amount] = String.split(vars, ", ")
      pointer = if registers[reg] == 1 do
        pointer + String.to_integer(amount)
      else
        pointer + 1
      end

      instruction = Enum.at(instructions, pointer)
      run_instruction(instructions, instruction, pointer, registers)
    end
  end

  defmodule Day24 do
    def part1 do
      container_weight = Advent15.stream!("15/24")
      |> Stream.map(&String.to_integer/1)
      |> Enum.sum
      |> Kernel.div(3)

      weights = Advent15.stream!("15/24")
      |> Enum.map(&String.to_integer/1)

      num_packages = Enum.count(weights) - 1

      for a <- num_packages-6..num_packages, b <- num_packages-5..num_packages-1, c <- num_packages-4..num_packages-2, d <- num_packages-7..num_packages-3, e <- 0..num_packages-4, f <- 0..num_packages-5 do
        {weight_a, remainder} = List.pop_at(weights, a)
        {weight_b, remainder} = List.pop_at(remainder, b)
        {weight_c, remainder} = List.pop_at(remainder, c)
        {weight_d, remainder} = List.pop_at(remainder, d)
        {weight_e, remainder} = List.pop_at(remainder, e)
        {weight_f, _} = List.pop_at(remainder, f)
        [weight_a, weight_b, weight_c, weight_d, weight_e, weight_f]
      end
      |> Enum.filter(fn [a, b, c, d, e, f] -> a + b + c + d + e + f == container_weight end)
      |> Enum.map(&Enum.sort/1)
      |> Enum.uniq
      |> Enum.map(&Enum.reduce(&1, fn x, acc -> x * acc end))
      |> Enum.min
    end

    def part2 do
      container_weight = Advent15.stream!("15/24")
      |> Stream.map(&String.to_integer/1)
      |> Enum.sum
      |> Kernel.div(4)

      weights = Advent15.stream!("15/24")
      |> Enum.map(&String.to_integer/1)

      num_packages = Enum.count(weights) - 1

      for a <- num_packages-7..num_packages, b <- num_packages-8..num_packages-1, c <- 0..num_packages-2, d <- 0..num_packages-3 do
        {weight_a, remainder} = List.pop_at(weights, a)
        {weight_b, remainder} = List.pop_at(remainder, b)
        {weight_c, remainder} = List.pop_at(remainder, c)
        {weight_d, _} = List.pop_at(remainder, d)
        [weight_a, weight_b, weight_c, weight_d]
      end
      |> Enum.filter(fn [a, b, c, d] -> a + b + c + d == container_weight end)
      |> Enum.map(&Enum.sort/1)
      |> Enum.uniq
      |> Enum.map(&Enum.reduce(&1, fn x, acc -> x * acc end))
      |> Enum.min
    end
  end

  defmodule Day25 do
    def part1 do
      [[row], [column]] = Regex.scan(~r/\d+/, Advent15.read!("15/25"))

      1..calc_number(String.to_integer(row), String.to_integer(column))-1
      |> Enum.reduce(20151125, &step/2)
    end

    defp calc_number(row, column) do
      n = row + column - 2
      div((1 + n) * n, 2) + column
    end

    defp step(_, previous), do: rem(previous * 252533, 33554393)
  end
end