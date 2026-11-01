"""Explicit D118 update: only weapon multiplier and revision of the selected mage."""
import argparse
import copy
import hashlib
import json
import os
from pathlib import Path


def update(path, preset_id, backup_dir):
    original=path.read_bytes()
    document=json.loads(original)
    if document.get('format')!='rpg.damage_lab.presets' or document.get('version')!=1:
        raise ValueError('Biblioteca incompatível; arquivo preservado.')
    selected=[p for p in document['presets'] if p['id']==preset_id]
    if len(selected)!=1 or selected[0]['actor'].get('character_id')!='ally_3':
        raise ValueError('Preset do mago não encontrado; arquivo preservado.')
    preset=selected[0]
    weapon=preset['equipment']['weapon']
    if weapon['id'] not in ['staff_wood','staff_oak','staff_ash','staff_yew','staff_ancient','staff_runic']:
        raise ValueError('Arma não é cajado; arquivo preservado.')
    if weapon['critical_multiplier']==1.5:
        return dict(status='already_updated',id=preset_id,revision=preset['revision'])
    before=copy.deepcopy(document)
    old_multiplier=weapon['critical_multiplier']
    weapon['critical_multiplier']=1.5
    preset['revision']+=1
    digest=hashlib.sha256(original).hexdigest()
    backup_dir.mkdir(parents=True,exist_ok=True)
    backup=backup_dir/f'presets-before-{digest[:12]}.json'
    if backup.exists() and backup.read_bytes()!=original:
        raise ValueError('Backup divergente; arquivo preservado.')
    backup.write_bytes(original)
    encoded=(json.dumps(document,ensure_ascii=False,indent=2)+'\n').encode()
    temporary=path.with_name(path.name+f'.{os.getpid()}.tmp')
    try:
        with temporary.open('xb') as stream:
            stream.write(encoded);stream.flush();os.fsync(stream.fileno())
        if path.read_bytes()!=original:
            raise ValueError('Biblioteca alterada simultaneamente; arquivo preservado.')
        os.replace(temporary,path)
    finally:
        temporary.unlink(missing_ok=True)
    reopened=json.loads(path.read_bytes())
    restored=copy.deepcopy(reopened)
    target=next(p for p in restored['presets'] if p['id']==preset_id)
    target['equipment']['weapon']['critical_multiplier']=old_multiplier
    target['revision']-=1
    assert restored==before
    return dict(status='updated',id=preset_id,old_multiplier=old_multiplier,new_multiplier=1.5,revision=preset['revision'],only_multiplier_and_revision_changed=True,backup=str(backup),before_sha256=digest,after_sha256=hashlib.sha256(path.read_bytes()).hexdigest())


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--library',type=Path,required=True)
    parser.add_argument('--preset-id',required=True)
    parser.add_argument('--backup-dir',type=Path,required=True)
    args=parser.parse_args()
    print(json.dumps(update(args.library,args.preset_id,args.backup_dir),ensure_ascii=False,indent=2))
