from transformers import TrainerCallback, TrainerState, TrainerControl
import httpx
import threading
import logging

logger = logging.getLogger(__name__)

class MetricsCallback(TrainerCallback):
    def __init__(self, callback_url: str = None):
        super().__init__()
        self.metrics_history = []
        self.callback_url = callback_url
        self.should_stop = False

    def on_step_end(self, args, state: TrainerState, control: TrainerControl, **kwargs):
        if self.should_stop:
            control.should_training_stop = True

    def on_log(self, args, state: TrainerState, control: TrainerControl, logs=None, **kwargs):
        if logs:
            metric = {
                "step": state.global_step,
                "epoch": state.epoch,
                "loss": logs.get("loss"),
                "learning_rate": logs.get("learning_rate")
            }
            self.metrics_history.append(metric)
            if self.callback_url:
                self._post_metrics(metric)

    def _post_metrics(self, metric):
        def _post():
            try:
                with httpx.Client() as client:
                    client.post(self.callback_url, json=metric, timeout=5.0)
            except Exception as e:
                logger.error(f"Failed to post metrics: {e}")
        
        threading.Thread(target=_post).start()
