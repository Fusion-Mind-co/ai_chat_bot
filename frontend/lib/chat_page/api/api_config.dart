// api_config.dart

// チャットの会話履歴の最大文字数
// 会話のつながりを把握するため

// GPTからの回答の制限トークン数
// 大きすぎるとエラーになる
// 小さすぎると文章が途中で途切れる
int answer_GPT_token_length = 2000;

double Free_max_monthly_cost = 2000; 
double Light_max_monthly_cost = 10000; 
double Standard_max_monthly_cost = 25000; 
double Pro_max_monthly_cost = 50000; 
double Expert_max_monthly_cost = 80000; 

List<String> GPT_Models = ['gpt-4o-mini' , 'gpt-3.5-turbo' , 'gpt-4o'];

// doubleは小数点を扱える型
// 公式HPより実際のレート

// https://openai.com/api/pricing/

double gpt_4o_mini_in_cost = 0.3;
double gpt_4o_mini_out_cost = 1.2;

double gpt_3_5_turbo_in_cost = 3.0;
double gpt_3_5_turbo_out_cost = 6.0;

double gpt_4o_in_cost = 3.75;
double gpt_4o_out_cost = 15.0;

// 公式サイトで○○トークンあたりのドルの○○で割る数
int divide_value = 1000000;

//ログイン情報の記憶時間の設定
int time_value = 300;

// GPT応答時タイムアウトエラー時間設定(秒)
int time_out_value = 60;
