"""MD event package merging and failure checks; no project files are mutated."""
import json,re,unittest
from pathlib import Path
from unittest.mock import patch
import compile_events

READ=Path.read_text
BASE=compile_events.BASE

class RoutePackages(unittest.TestCase):
    def test_preserve_original_ids_and_explicit_replacements(self):
        original=json.loads(READ(BASE/'catalog.json',encoding='utf8'))
        data=compile_events.load_catalog()
        self.assertTrue(set(original['events'])<=set(data['events']))
        for key,value in original['events'].items():
            if key not in ['SJ-C04','DN-C02','CH-C02']: self.assertEqual(value,data['events'][key])
        self.assertEqual(data['defaults']['vars']['sy_stage'],0)
        self.assertEqual(data['defaults']['vars']['hr_stage'],0)
        self.assertEqual(len(data['route_companions']),2)

    def changed_package(self,change,expected):
        path=BASE/'routes/장소연_전용루트.md'
        text=READ(path,encoding='utf8')
        match=re.search(r'^```route-json\n(.*?)^```',text,re.M|re.S)
        package=json.loads(match[1]);change(package)
        altered=text[:match.start(1)]+json.dumps(package,ensure_ascii=False)+'\n'+text[match.end(1):]
        def read(p,*args,**kwargs):return altered if p==path else READ(p,*args,**kwargs)
        with patch.object(Path,'read_text',read),self.assertRaisesRegex(AssertionError,expected):compile_events.load_catalog()

    def test_unannounced_overwrite_rejected(self):
        self.changed_package(lambda p:p.update(replace_events=[]),'Declare existing event replacement')

    def test_existing_save_default_cannot_be_overwritten(self):
        self.changed_package(lambda p:p['defaults']['vars'].update(my_trust=100),'Duplicate default')

    def test_source_cannot_escape_directory(self):
        path=BASE/'manifest.json';manifest=json.loads(READ(path,encoding='utf8'));manifest['route_sources']=['../README.md']
        def read(p,*args,**kwargs):return json.dumps(manifest) if p==path else READ(p,*args,**kwargs)
        with patch.object(Path,'read_text',read),self.assertRaisesRegex(AssertionError,'outside'):compile_events.load_catalog()

if __name__=='__main__':unittest.main()
