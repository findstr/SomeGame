using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraFollow : MonoBehaviour
{
    public Vector3 offset;
    public GameObject target = null;
    void LateUpdate()
    {
        if (target != null) {
            transform.position = target.transform.position + Quaternion.AngleAxis(transform.rotation.eulerAngles.y, Vector3.up) * offset;
        }
    }
}
