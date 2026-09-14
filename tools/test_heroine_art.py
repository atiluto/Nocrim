"""Focused data/validation regression checks for expressions and weather."""
import json,unittest
from unittest.mock import patch
from pathlib import Path
import compile_scenario

BASE=compile_scenario.ROOT/'scenario/events'
READ=Path.read_text

class HeroineArt(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data=compile_scenario.compile_data(BASE,True)
        cls.beats={b['id']:b for b in cls.data['beats']}

    def test_reveal_exit_and_cg(self):
        b=self.beats
        self.assertFalse(b['MY-AG-01-COMMON-011']['actors'])
        self.assertEqual(b['MY-AG-01-COMMON-012']['actors'][0]['id'],'ma_yeongran')
        self.assertFalse(b['MY-AG-01-TAIL-005']['actors'])
        self.assertFalse(b['MY-JS-03-COMMON-003']['actors'])
        self.assertFalse(b['MY-TB-01-COMMON-001']['actors'])
        self.assertEqual(b['MY-BU-03-COMMON-026']['background'],'cg_ma_bandage')
        self.assertFalse(b['MY-BU-03-COMMON-026']['actors'])

    def test_expression_variants_and_weather(self):
        b=self.beats
        self.assertEqual(b['MY-SB-04-COMMON-014']['actors'][0]['expression'],'surprised')
        self.assertEqual(b['MY-SJ-04-COMMON-012']['actors'][0]['expression'],'shy')
        self.assertEqual(b['MY-BU-04-COMMON-010']['weather'],'rain')
        self.assertEqual(b['MY-SB-03-COMMON-001']['weather'],'snow')
        self.assertEqual(b['MY-SB-04-COMMON-001']['weather'],'')
        self.assertEqual(sum(key.startswith('MY-') for key in b),804)

    def reject(self,filename,change,expected):
        target=BASE/filename
        value=json.loads(READ(target,encoding='utf8')); change(value)
        def override(path,*args,**kwargs):
            return json.dumps(value,ensure_ascii=False) if path==target else READ(path,*args,**kwargs)
        with patch.object(Path,'read_text',override), self.assertRaisesRegex(ValueError,expected):
            compile_scenario.compile_data(BASE,True)

    def test_invalid_expression(self):
        self.reject('staging.json',lambda d:d['cues']['MY-AG-01-COMMON-012']['expressions'].update(ma_yeongran='not_created'),'Unknown actor/expression')

    def test_wrong_role(self):
        self.reject('staging.json',lambda d:d['sprite_roles'].update(ma_yeongran_smile='merchant'),'role mismatch')

    def test_invalid_weather(self):
        self.reject('presentation.json',lambda d:d['weather'].update({'MY-R-08-COMMON-001':'typhoon'}),'Weather must')

    def test_unknown_weather_id(self):
        self.reject('presentation.json',lambda d:d['weather'].update({'NO-SUCH-BEAT':'rain'}),'Unknown weather IDs')

    def test_invalid_background_path(self):
        self.reject('presentation.json',lambda d:d['backgrounds'].append('../unknown'),'Background registry')

if __name__=='__main__': unittest.main()
