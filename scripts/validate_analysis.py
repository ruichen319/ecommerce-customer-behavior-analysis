"""Independently reconcile analysis definitions against cleaned CSV (requires pandas).
Usage: python scripts/validate_analysis.py /path/to/cleaned_data.csv
This checks analytical results; it does not execute or certify MySQL scripts.
"""
import json
import sys
from pathlib import Path
import pandas as pd

clicks, other = [], []
for chunk in pd.read_csv(sys.argv[1], usecols=['user_id','item_category','behavior_type','time'],
                         dtype={'user_id':'int64','item_category':'int32','behavior_type':'int8'}, chunksize=500000):
    chunk['ts'] = pd.to_datetime(chunk.pop('time'), format='%Y-%m-%d %H')
    clicks.append(chunk[chunk.behavior_type.eq(1)].groupby(['user_id','item_category']).ts.min())
    other.append(chunk[chunk.behavior_type.ne(1)])
keys = ['user_id','item_category']
c = pd.concat(clicks).groupby(level=[0,1]).min().rename('first_click').reset_index()
b = pd.concat(other, ignore_index=True)
e = b[b.behavior_type.isin([2,3])].merge(c,on=keys)
e = e[e.ts.gt(e.first_click)].groupby(keys).ts.min().rename('first_engage').reset_index()
buy = b[b.behavior_type.eq(4)]
f = buy.merge(e,on=keys)
f = f[f.ts.gt(f.first_engage)]
first_buy = f.groupby(keys).ts.min().rename('first_buy').reset_index()
funnel = c.merge(e,on=keys,how='left').merge(first_buy,on=keys,how='left')
cat = funnel.groupby('item_category').agg(click_users=('user_id','size'),engage_users=('first_engage','count'),buy_users=('first_buy','count'))
cat = cat[(cat.click_users>=30)&(cat.engage_users>=30)]
all_category_funnel_events = len(f)
all_purchase_pairs = buy.groupby(keys).size()
eligible_purchases = buy[buy.item_category.isin(cat.index)]
f = f[f.item_category.isin(cat.index)].copy()
f['day'] = f.ts.dt.date
pairs = f.groupby(keys).agg(events=('ts','size'),days=('day','nunique'))
cart = b[b.behavior_type.eq(3)].merge(c[c.item_category.isin(cat.index)],on=keys)
cart = cart[cart.ts.gt(cart.first_click)].groupby(keys).ts.min().rename('cart_time').reset_index()
cb = buy.merge(cart,on=keys)
cb = cb[cb.ts.gt(cb.cart_time)].groupby(keys).ts.min().rename('buy_time').reset_index()
cart = cart.merge(cb,on=keys,how='left')
cart['seconds'] = (cart.buy_time-cart.cart_time).dt.total_seconds()
observed = cart[cart.buy_time.notna()].sort_values(['item_category','seconds','user_id']).copy()
observed['n'] = observed.groupby('item_category').user_id.transform('size')
observed['rank'] = observed.groupby('item_category').cumcount()+1
import numpy as np
benchmark = observed[(observed.n>=5)&(observed['rank']==np.ceil(.8*observed.n))][['item_category','seconds']].rename(columns={'seconds':'benchmark'})
cart = cart.merge(benchmark,on='item_category',how='left')
end = max(c.first_click.max(), b.ts.max())
cart['status'] = np.select([cart.benchmark.isna(),cart.buy_time.notna()&cart.seconds.le(cart.benchmark),cart.buy_time.notna(),(end-cart.cart_time).dt.total_seconds().ge(cart.benchmark)],['no category benchmark','purchased within benchmark','purchased after benchmark','no purchase observed'],default='insufficient follow-up')
result = {'eligible_categories':len(cat),'click_pairs':int(cat.click_users.sum()),'engage_pairs':int(cat.engage_users.sum()),'buy_pairs':int(cat.buy_users.sum()),'funnel_purchase_events':len(f),'repeat_pairs':int((pairs.days>=2).sum()),'repeat_purchase_events':int(pairs.loc[pairs.days>=2,'events'].sum()),'cart_status':{k:int(v) for k,v in cart.status.value_counts().items()},'cart_top10':{str(k):int(v) for k,v in cart[cart.status.eq('no purchase observed')].groupby('item_category').size().sort_values(ascending=False).head(10).items()}}
expected = {'eligible_categories':680,'click_pairs':588488,'engage_pairs':104079,'buy_pairs':21259,'funnel_purchase_events':37162,'repeat_pairs':2700,'repeat_purchase_events':10825}
result['purchase_scope'] = {'all_category_funnel_events':all_category_funnel_events,'all_purchase_events':len(buy),'all_purchase_pairs':len(all_purchase_pairs),'eligible_purchase_events':len(eligible_purchases),'eligible_purchase_pairs':len(eligible_purchases.groupby(keys))}
result['corrected_repeat_event_share_pct'] = round(100*result['repeat_purchase_events']/len(f),2)
result['corrected_funnel_coverage_pct'] = round(100*len(f)/len(eligible_purchases),2)
result['matches_report'] = {k:result[k]==v for k,v in expected.items()}
expected_cart = {'no purchase observed':37605,'insufficient follow-up':15972,'purchased within benchmark':13845,'purchased after benchmark':3176,'no category benchmark':2559}
result['cart_matches_report'] = result['cart_status']==expected_cart
out = Path(__file__).resolve().parents[1]/'docs'/'analysis-validation.json'
out.write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
if not all(result['matches_report'].values()) or not result['cart_matches_report']:
    sys.exit(1)
