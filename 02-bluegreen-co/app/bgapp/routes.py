from flask import Blueprint, jsonify, current_app
from sqlalchemy import text
from .extensions import db
from .models import Item

bp = Blueprint('main', __name__)

@bp.route('/')
def index():
    return jsonify({
        "app": "BlueGreen Co. API",
        "color": current_app.config['APP_COLOR'],
        "version": current_app.config['APP_VERSION']
    })

@bp.route('/version')
def version():
    return jsonify({
        "color": current_app.config['APP_COLOR'],
        "version": current_app.config['APP_VERSION']
    })

@bp.route('/health')
def health():
    """Liveness probe: O pod está vivo?"""
    return jsonify({"status": "alive"}), 200

@bp.route('/readiness')
def readiness():
    """Readiness probe: O pod está pronto para receber tráfego? (Checa o banco)"""
    try:
        db.session.execute(text('SELECT 1'))
        return jsonify({"status": "ready", "database": "connected"}), 200
    except Exception as e:
        return jsonify({"status": "not ready", "error": str(e)}), 503

@bp.route('/db')
def write_read_db():
    """Prova de persistência: Grava um item e conta o total."""
    try:
        new_item = Item(name=f"Item da versão {current_app.config['APP_VERSION']}")
        db.session.add(new_item)
        db.session.commit()
        
        count = Item.query.count()
        return jsonify({
            "message": "Item criado com sucesso",
            "total_items": count,
            "last_item_id": new_item.id
        }), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500

@bp.route('/debug/degrade')
def degrade():
    """Endpoint de caos controlado para simular falhas no lado Green."""
    if current_app.config['APP_FAIL_MODE']:
        return jsonify({"error": "Internal Server Error (Simulated)"}), 500
    return jsonify({"status": "ok", "message": "App healthy (fail mode is OFF)"}), 200