"""Install the approved lab preset once, preserving existing preset records.

Run after Godot validation; --library explicitly selects the local library.
No automatic import runs when the game starts.
"""
import argparse
import hashlib
import json
import os
import time
from pathlib import Path


def install(library: Path, backup_dir: Path) -> dict:
    recipe_path = Path(__file__).resolve().parents[2] / 'data/damage_lab_enemy_02.json'
    recipe = json.loads(recipe_path.read_text())
    original = library.read_bytes() if library.exists() else None
    document = json.loads(original) if original is not None else {
        'format': 'rpg.damage_lab.presets', 'version': 1, 'presets': []}
    if document.get('format') != 'rpg.damage_lab.presets' or document.get('version') != 1 or not isinstance(document.get('presets'), list):
        raise ValueError('Formato da biblioteca incompatível; arquivo preservado.')
    previous = document['presets'][:]
    matches = [p for p in previous if p.get('side') == 'enemy' and p.get('actor', {}).get('id') == 'enemy_ranged' and p.get('name') == recipe['name']]
    if matches:
        return {'status': 'already_installed', 'id': matches[0]['id'], 'previous_records_unchanged': True}
    if any(p.get('side') == 'enemy' and p.get('name', '').strip().casefold() == recipe['name'].casefold() for p in previous):
        raise ValueError('Nome já usado por outro preset; arquivo preservado.')
    entry = dict(recipe, id=f'user_ranged_{time.time_ns()}', revision=1)
    document['presets'].append(entry)
    backup_dir.mkdir(parents=True, exist_ok=True)
    digest = hashlib.sha256(original or b'').hexdigest()
    backup = backup_dir / f'presets-before-{digest[:12]}.json'
    if original is not None:
        if backup.exists() and backup.read_bytes() != original:
            raise ValueError('Backup existente diverge; arquivo preservado.')
        backup.write_bytes(original)
    encoded = (json.dumps(document, ensure_ascii=False, indent=2) + '\n').encode()
    candidate = json.loads(encoded)
    assert candidate['presets'][:-1] == previous
    library.parent.mkdir(parents=True, exist_ok=True)
    temporary = library.with_name(library.name + f'.{os.getpid()}.tmp')
    try:
        with temporary.open('xb') as stream:
            stream.write(encoded)
            stream.flush()
            os.fsync(stream.fileno())
        if (library.read_bytes() if library.exists() else None) != original:
            raise ValueError('Biblioteca mudou durante o cadastro; tente novamente. Arquivo preservado.')
        os.replace(temporary, library)
    finally:
        temporary.unlink(missing_ok=True)
    reopened = json.loads(library.read_bytes())
    assert reopened['presets'][:-1] == previous and reopened['presets'][-1] == entry
    return {'status': 'installed', 'id': entry['id'], 'name': entry['name'], 'backup': str(backup) if original is not None else None, 'before_sha256': digest, 'after_sha256': hashlib.sha256(library.read_bytes()).hexdigest(), 'previous_records_unchanged': True, 'preset_count': len(reopened['presets'])}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--library', type=Path, required=True)
    parser.add_argument('--backup-dir', type=Path, required=True)
    args = parser.parse_args()
    result = install(args.library, args.backup_dir)
    print(json.dumps(result, ensure_ascii=False, indent=2))
